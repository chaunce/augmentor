require File.expand_path('../test_helper', __FILE__)

class AugmentorTest < Test::Unit::TestCase
  def setup
    @name = 'John Doe'
    @password = 'p@$$w0rd'
    @login = 'john'
    @duplicate = 'duplicate'

    @different = 'different'
    @changed = 'changed'
    @bob = 'bob'
    @robert = 'robert'
    @jim = 'jim'

    @user_count = User.count
    @user_created = 0
    @person_count = Person.count
    @person_created = 0
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
    if user.save!
      @user_created += 1
      @person_created += 1
    end
    user = User.find(user.id)
    assert_equal @name, user.name
    assert_equal @login, user.login
    assert_equal @password, user.password
    assert_equal @user_created, User.count
    assert_equal @person_created, Person.count
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

    person.duplicate = @different
    person.save!
    user = User.find(user.id)
    person = Person.find(user.person.id)
    assert_equal @different, person.attributes['duplicate']
    assert_equal @duplicate, user.attributes['duplicate']

    user.duplicate = @changed
    user.save!
    user = User.find(user.id)
    person = Person.find(user.person.id)
    assert_equal @different, person.attributes['duplicate']
    assert_equal @changed, user.attributes['duplicate']
  end

  def test_destroy_augmented_will_destroy_augmentor
    user = User.new
    user.name = @name
    user.login = @login
    user.password = @password
    if user.save!
      @user_created += 1
      @person_created += 1
    end
    assert_equal @user_count + @user_created, User.count
    assert_equal @person_count + @person_created, Person.count
    user_id = user.id
    person_id = user.person.id
    if user.destroy
      @user_created -= 1
      @person_created -= 1
    end
    assert_equal @user_count + @user_created, User.count
    assert_equal @person_count + @person_created, Person.count
    assert !User.exists?(user_id)
    assert !Person.exists?(person_id)
  end

  def test_inherits_augmentor_methods
    person_jim = Person.new
    person_jim.name = @jim
    assert person_jim.is_jim?
    person_jim.name = @bob
    assert !person_jim.is_jim?

    user_jim = User.new
    assert user_jim.respond_to? :is_jim?
    user_jim.name = @jim
    assert user_jim.is_jim?
    user_jim.name = @bob
    assert !user_jim.is_jim?

    person_jims_count = Person.find_jims.length
    user_jims_count = User.find_jims.length
    user_jim.name = @jim
    if user_jim.save!
      person_jims_count += 1
      user_jims_count += 1
    end
    assert_equal person_jims_count, Person.find_jims.length
    assert_equal user_jims_count, User.find_jims.length
    assert_equal Person.find_jims.length, User.find_jims.length
  end

  def test_may_override_augmentor_methods
    person_bob = Person.new
    person_bob.name = @bob
    assert person_bob.is_bob?
    person_bob.name = @robert
    assert !person_bob.is_bob?

    user_bob = User.new
    assert user_bob.respond_to? :is_bob?
    user_bob.name = @bob
    assert user_bob.is_bob?
    user_bob.name = @robert
    assert user_bob.is_bob?
    user_bob.name = @jim
    assert !user_bob.is_bob?

    person_bob_count = Person.find_bobs.length
    user_bob_count = User.find_bobs.length
    user_bob = User.new
    user_bob.name = @robert
    if user_bob.save!
      user_bob_count += 1
    end
    assert_equal person_bob_count, Person.find_bobs.length
    assert_equal user_bob_count, User.find_bobs.length
    assert_not_equal Person.find_bobs.length, User.find_bobs.length
    user_bob.name = @bob
    if user_bob.save!
      person_bob_count += 1
    end
    assert_equal person_bob_count, Person.find_bobs.length
    assert_equal Person.find_bobs.length, User.find_bobs.length

    user_bob = User.new
    user_bob.name = @bob
    user_bob.save!
    assert_equal Person.find_bobs.length, User.find_bobs.length
  end

  def test_properly_returns_changed_and_changes
    user_bob = User.new
    assert !user_bob.changed?
    assert_equal Hash.new, user_bob.changes

    user_bob.name = @bob
    assert user_bob.changed?
    assert_equal Hash[name: [nil, @bob]].stringify_keys, user_bob.changes

    user_bob.login = @login
    assert user_bob.changed?
    assert_equal Hash[name: [nil, @bob], login: [nil, @login]].stringify_keys, user_bob.changes

    user_bob.save!
    assert !user_bob.changed?
    assert_equal Hash.new, user_bob.changes
  end

  def test_validations
    person_bob = Person.new
    assert !person_bob.valid?
    assert_equal [:user, :name], person_bob.errors.keys
    person_bob.build_user
    person_bob.name = @bob
    assert person_bob.valid?

    user_bob = User.new
    assert !user_bob.valid?
    assert_equal [:name], user_bob.errors.keys
    user_bob.name = @bob
    assert user_bob.valid?
  end
end