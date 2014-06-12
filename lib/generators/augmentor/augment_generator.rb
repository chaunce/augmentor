require 'rails/generators'
require 'rails/generators/migration'
require 'rails/generators/active_record'

module Augmentor
  module Generators
    class AugmentGenerator < ::Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path('../templates', __FILE__)

      argument :augmented_class, :type => :string
      argument :extension_class, :type => :string

      def self.next_migration_number(path)
        ActiveRecord::Generators::Base.next_migration_number(path)
      end

      def copy_migration
        migration_template 'augment_migration.rb', "db/migrate/add_#{extension_class.underscore.singularize}_as_augmentor_to_#{augmented_class.underscore.singularize}.rb"
      end

    end
  end
end