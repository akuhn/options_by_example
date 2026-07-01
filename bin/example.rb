#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative %(../lib/options_by_example)


flags = OptionsByExample.read(DATA).parse(ARGV)

puts 'Feeling verbose today' if flags.include_verbose?
puts flags.get_words.sample(flags.get_num)

__END__
Choose at random from a list of provided words.

Usage: random.rb [options] words ...

Options:
  -n, --num NUM     Number of choices (default 1)
  --verbose         Enable verbose mode
