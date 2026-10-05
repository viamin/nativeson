# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Declare your gem's dependencies in nativeson.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# To use a debugger
# gem 'byebug', group: [:development, :test]
#
#

group :development do
  gem 'active_model_serializers'
  gem 'benchmark-ips'
  gem 'connection_pool', '< 3'
  gem 'faker', '< 3.9', require: false
  gem 'gruff'
  gem 'memory_profiler'
  gem 'panko_serializer'
  gem 'parallel', '< 2', require: false
  gem 'rails-erd'
  gem 'rmagick', '< 7'
  gem 'rubocop', require: false
end

group :development, :test do
  gem 'activerecord-import'
  gem 'annotate_models'
  gem 'colorize'
  gem 'deepsort'
  gem 'minitest', '< 6'
  gem 'multi_json', '< 1.22'
  gem 'oj'
  gem 'pry'
  gem 'sprockets-rails'
  gem 'yajl'
end
