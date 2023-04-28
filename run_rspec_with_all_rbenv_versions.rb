#!/bin/bash

eval "$(rbenv init -)"

for version in $(rbenv versions --bare); do
  rbenv shell $version
  printf -- '-%.0s' {1..72}; echo
  echo "Using $(ruby --version)"
  bundle exec rspec
done

rbenv shell system
