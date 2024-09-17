#!/bin/bash

echo "Updating RubyGems..."
gem update --system -N

echo "Installing dependencies..."
# Bigdecimal fails to compile natively on Ubuntu with
# Ruby 3.3.4. This is a workaround to fix that.
# See: https://github.com/ruby/bigdecimal/issues/297
export CC=/usr/bin/clang && export CXX=/usr/bin/clang++
bundle install
yarn install
yarn build
yarn build:css

echo "Creating database..."
bin/rails db:prepare 

echo "Done!"
