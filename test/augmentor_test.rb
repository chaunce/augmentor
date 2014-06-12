require File.expand_path('../test_helper', __FILE__)

class AugmentorTest < Test::Unit::TestCase
  def test_setup
    @name = 'John Doe'
    @password = 'p@$$w0rd'
    @login = 'john'
    @duplicate = 'duplicate'
  end

  def setup
    @user_count = User.count
    @person_count = Person.count
  end

  def test_associations_are_implemented
    user = User.new
    assert user.person.present?
  end

  def test_can_set_save_and_get_augmentor_attributes
    user = User.new
    user.name = @name
    user.login = @login
    user.password = @password
    user.save!
    user = User.find(user.id)
    assert_equal @name, user.name
    assert_equal @login, user.login
    assert_equal @password, user.password
    assert_equal @user_count+1, User.count
    assert_equal @person_count+1, Person.count
    assert_equal @name, Person.last.attributes['name']
    assert_equal @login, User.last.attributes['login']
    assert_equal @password, User.last.attributes['password']
  end
  
  def test_duplicate_augmentor_attributes_are_ignored
    user = User.new
    user.name = @name
    user.login = @login
    user.password = @password
    user.duplicate = @duplicate
    user.save!

    user = User.find(user.id)
    person = Person.find(user.person.id)
    assert_equal @name, person.attributes['name']
    assert_nil person.attributes['duplicate']
    assert_equal @login, user.attributes['login']
    assert_equal @password, user.attributes['password']
    assert_equal @duplicate, user.attributes['duplicate']

    person.duplicate = 'different'
    person.save!
    user = User.find(user.id)
    person = Person.find(user.person.id)
    assert_equal 'different', person.attributes['duplicate']
    assert_equal @duplicate, user.attributes['duplicate']

    user.duplicate = 'changed'
    user.save!
    user = User.find(user.id)
    person = Person.find(user.person.id)
    assert_equal 'different', person.attributes['duplicate']
    assert_equal 'changed', user.attributes['duplicate']
  end

  def test_destroy_augmented_will_destroy_augmentor
    user = User.new
    user.name = @name
    user.login = @login
    user.password = @password
    user.save
    assert_equal @user_count+1, User.count
    assert_equal @person_count+1, Person.count
    user_id = user.id
    person_id = user.person.id
    user.destroy
    assert_equal @user_count, User.count
    assert_equal @person_count, Person.count
    assert !User.exists?(user_id)
    assert !Person.exists?(person_id)
  end
  
  def test_inherits_augmentor_methods
    person_jim = Person.new
    person_jim.name = 'jim'
    assert person_jim.is_jim?
    person_jim.name = 'bob'
    assert !person_jim.is_jim?

    user_jim = User.new
    assert user_jim.respond_to? :is_jim?
    user_jim.name = 'jim'
    assert user_jim.is_jim?
    user_jim.name = 'bob'
    assert !user_jim.is_jim?
  end
  
  def test_may_override_augmentor_methods
    person_bob = Person.new
    person_bob.name = 'bob'
    assert person_bob.is_bob?
    person_bob.name = 'robert'
    assert !person_bob.is_bob?

    user_bob = User.new
    assert user_bob.respond_to? :is_bob?
    user_bob.name = 'bob'
    assert user_bob.is_bob?
    user_bob.name = 'robert'
    assert user_bob.is_bob?
    user_bob.name = 'jim'
    assert !user_bob.is_bob?
  end

end