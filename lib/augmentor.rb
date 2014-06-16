require 'active_support'
require 'active_record'

module Augmentor
  autoload :Version, 'augmentor/version'

  module ActiveRecord
    extend ActiveSupport::Concern

    module ClassMethods
      def augment(*arguments)
        validate_augmentor_arguments(arguments)
        klass, options, klass_name = parse_augmentor_arguments(arguments)
        belongs_to klass, options
        validates_presence_of :"#{klass}"
      end

      def augmented_by(*arguments)
        validate_augmentor_arguments(arguments)
        klass, options, klass_name = parse_augmentor_arguments(arguments)
        has_one klass, {dependent: :destroy, inverse_of: :"#{self.name.underscore}"}.merge(options)
        define_method "#{klass}_must_be_valid" do
          if self.send(klass).valid?
            true
          else
            self.errors.messages.merge!(self.send(klass).errors.messages)
            false
          end
        end
        validate :"#{klass}_must_be_valid"

        define_method "#{klass}_with_autobuild" do
          self.send(:"#{klass}_without_autobuild") || self.send(:"build_#{klass}")
        end
        alias_method_chain :"#{klass}", :autobuild

        define_method "changed_with_#{klass}?" do
          self.send(:"changed_without_#{klass}?") || self.send(klass).send(:changed?)
        end
        alias_method_chain :changed?, :"#{klass}"

        define_method "changes_with_#{klass}" do
          self.send(:"changes_without_#{klass}").merge(self.send(klass).send(:changes))
        end
        alias_method_chain :changes, :"#{klass}"

        define_method "save_with_#{klass}" do |*arguments|
          self.send(klass).send(:save, *arguments) && self.send(:"save_without_#{klass}", *arguments)
        end
        alias_method_chain :save, :"#{klass}"

        define_method "save_with_#{klass}!" do |*arguments|
          self.send(klass).send(:save!, *arguments) && self.send(:"save_without_#{klass}!", *arguments)
        end
        alias_method_chain :save!, :"#{klass}"

        after_initialize do
          all_attributes = klass_name.constantize.content_columns.map(&:name)
          attributes_to_delegate = all_attributes - self.class.content_columns.map(&:name)
          attributes_to_delegate.each do |attrib|
            class_eval <<-RUBY
              def #{attrib}
                #{klass}.#{attrib}
              end
              def #{attrib}=(value)
                self.#{klass}.#{attrib} = value
              end
              def #{attrib}?
                self.#{klass}.#{attrib}?
              end
            RUBY
          end
        end

        define_method "method_missing_with_#{klass}" do |*arguments|
          self.send(klass).send(*arguments) rescue self.send(:"method_missing_without_#{klass}", *arguments)
        end
        alias_method_chain :method_missing, :"#{klass}"

        define_method "respond_to_with_#{klass}?" do |*arguments|
          self.send(:"respond_to_without_#{klass}?", *arguments) || self.send(klass).send(:respond_to?, *arguments)
        end
        alias_method_chain :respond_to?, :"#{klass}"
      end

    private

      def validate_augmentor_arguments(arguments)
        raise ArgumentError, "wrong number of arguments (#{arguments.length} for 1+)" unless arguments.length >= 1
      end
      def parse_augmentor_arguments(arguments)
        parse_arguments = arguments.dup
        options = arguments.extract_options!
        klass = arguments.first
        klass_name = options[:class_name] || klass.to_s.classify
        return klass, options, klass_name
      end
    end

  end

  module SchemaDefinitions
    module AugmentMethod
      def augment(*arguments)
        options = (arguments.extract_options!).merge({index:true})
        arguments.each do |col|
          column("#{col}_id", :integer, options)
        end
      end
    end
    def self.load!
      ::ActiveRecord::ConnectionAdapters::TableDefinition.class_eval { include Augmentor::SchemaDefinitions::AugmentMethod }
    end
  end

end

ActiveSupport.on_load :active_record do
  Augmentor::SchemaDefinitions.load!
  ActiveRecord::Base.send(:include, Augmentor::ActiveRecord)
end