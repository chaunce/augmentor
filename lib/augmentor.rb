require 'active_support'
require 'active_record'

module Augmentor
  autoload :Version, 'augmentor/version'

  module ActiveRecord
    extend ActiveSupport::Concern

    module ClassMethods
      def augment(*args)
        validate_augmentor_args(args)
        klass, options, klass_name = parse_augmentor_args(args)
        belongs_to klass, options
        validates_presence_of :"#{klass}"
      end

      def augmented_by(*args)
        validate_augmentor_args(args)
        klass, options, klass_name = parse_augmentor_args(args)
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
      end

    private

      def validate_augmentor_args(args)
        raise ArgumentError, "wrong number of arguments (#{args.length} for 1+)" unless args.length >= 1
      end
      def parse_augmentor_args(args)
        parse_args = args.dup
        options = args.extract_options!
        klass = args.first
        klass_name = options[:class_name] || klass.to_s.classify
        return klass, options, klass_name
      end
    end

  end

  module SchemaDefinitions
    module AugmentMethod
      def augment(*args)
        options = (args.extract_options!).merge({index:true})
        args.each do |col|
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