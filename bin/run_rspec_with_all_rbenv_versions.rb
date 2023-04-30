#!/bin/bash

# Remove the "BUNDLED WITH" section in Gemfile.lock to prevent potential
# issues when using different versions of Ruby and Bundler
sed -i '' '/BUNDLED WITH/,$d' Gemfile.lock

# Enable rbenv shell integration
eval "$(rbenv init -)"

for version in $(rbenv versions --bare); do
  rbenv shell $version
  printf -- '-%.0s' {1..72}; echo
  echo "Using $(ruby --version)"
  rspec --format progress
done

rbenv shell system
