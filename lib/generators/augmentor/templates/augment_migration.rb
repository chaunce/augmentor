class Add<%= extension_class.camelize.singularize %>AsAugmentorTo<%= augmented_class.camelize.singularize %> < ActiveRecord::Migration
  def change
    change_table :<%= extension_class.underscore.pluralize %> do |t|
      t.augment :<%= augmented_class.underscore.singularize %>, index: true
    end
  end
end