lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'augmentor/version'
require 'date'

Gem::Specification.new do |s|
  s.name    = 'augmentor'
  s.version = Augmentor::Version.string
  s.date    = Date.today

  s.summary     = 'Augment an ActiveRecord class by including additional extension classes'
  s.description = 'Augment an ActiveRecord class by including one or moe additional ActiveRecord extension classes.  The augmented class will inherit all attributes and methods, including those provided by ActiveRecord such as getters and setters, as local.'
  s.license     = 'MIT'

  s.author   = 'chaunce'
  s.email    = 'chaunce.slc@gmail.com'
  s.homepage = 'http://github.com/chaunce/augmentor'

  s.has_rdoc = false
  s.rdoc_options = ['--line-numbers', '--inline-source', '--main', 'README.rdoc']

  s.require_paths = ['lib']

  s.files       = `git ls-files`.split("\n")
  s.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")

  s.add_dependency('rails', ['>= 3.2'])
  s.add_development_dependency('sqlite3')
end