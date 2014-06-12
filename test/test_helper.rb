$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$:.unshift(File.dirname(__FILE__))
require 'augmentor'

require 'active_record'
require 'sqlite3'
require 'test/unit'
require 'debugger'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

ActiveRecord::Schema.define(:version => 1) do
  create_table :people do |t|
    t.string :name
    t.string :duplicate
    t.augment :user
  end
  create_table :users do |t|
    t.string :login
    t.string :duplicate
    t.string :password
  end
end

class Person < ActiveRecord::Base
  augment :user

  def is_bob?
    self.name == 'bob'
  end

  def is_jim?
    self.name == 'jim'
  end
end

class User < ActiveRecord::Base
  augmented_by :person

  def is_bob?
    ['robert', 'rob', 'bob'].include?(self.name)
  end
end