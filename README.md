# augmentor

Augment an ActiveRecord class by including additional ActiveRecord classes

The Augmentor gem allows an ActiveRecord class to inherit all attributes and methods from one or more other ActiveRecord classes, including those provided by ActiveRecord such as getters and setters, as local.

This allows you to effectively span the data stored for an ActiveRecord class across multiple table without using ActiveRecord relations to get or set the data.  To ensure best performance, data 

## Dependencies

the following gems are required

    gem 'rails', '>= 3.2'

## Installation

install manually

    gem install augmentor

or add it to your Gemfile

    gem 'augmentor'

## Usage

### Update Database

#### create migration to add augmentor associations field to an existing class

    rails generate augmentor:augment user person
    rake db:migrate

#### or create migration to add augmentor associations field to a new class

    rails generate model person first_name:string, last_name:string, user:augment
    rake db:migrate

### Update Models

#### include in the augmented class

    class User < ActiveRecord::Base
      augmented_by :person
    
    end

#### include in the augmenting class

    class Person < ActiveRecord::Base
      augment :user
    
    end

##### augmentor associations accepts many ActiveRecord association options, but will only associate one level deep and can not use :through

class User < ActiveRecord::Base
  augmented_by :individual, class_name: :person, inverse_of: :user

end

