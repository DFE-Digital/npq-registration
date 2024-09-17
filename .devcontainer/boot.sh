#!/bin/bash

echo "Updating RubyGems..."
gem update --system -N

echo "Installing dependencies..."
bundle install
yarn install
yarn build
yarn build:css

echo "Creating database..."
bin/rails db:prepare 

echo "Done!"
