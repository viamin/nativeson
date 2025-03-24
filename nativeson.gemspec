# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'nativeson/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name = 'nativeson'
  s.version = Nativeson::VERSION
  s.authors = ['Ohad Dahan', 'Al Chou']
  s.email = ['HotFusionMan+GitLab-Nativeson@Gmail.com']
  s.summary = 'nativeson'
  s.description = 'Methods to generate JSON from database records using database-native functions for speed.'
  s.homepage = 'https://gitlab.com/Nativeson/nativeson'
  s.license = 'Apache-2.0'

  s.files = Dir['{app,config,db,lib}/**/*', 'LICENSE', 'Rakefile', 'README.md']

  s.add_dependency 'pg'
  s.add_dependency 'rails', '>= 6.1', '< 9.0'

  # s.add_development_dependency 'mysql'
  # s.add_development_dependency 'sqlite3'
end
