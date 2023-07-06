#!/bin/bash

set -e

bundle install
git checkout -- Gemfile.lock
pushd test/dummy
bundle exec rake db:prepare
git checkout -- db/schema.rb
popd
