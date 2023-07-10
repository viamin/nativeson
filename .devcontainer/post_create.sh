#!/bin/bash

set -e

git config --global --add safe.directory /workspace
bundle install
git checkout -- Gemfile.lock
pushd test/dummy
bundle exec rake db:prepare
git checkout -- db/schema.rb
popd
