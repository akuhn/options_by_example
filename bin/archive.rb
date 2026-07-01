#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'options_by_example'

flags = OptionsByExample.read(DATA).parse(ARGV)

puts "Archiving #{flags.get_source}"
if flags.include_compress?
  puts "Compressing#{flags.get_compress ? " at #{flags.get_compress} level" : ''}"
end

__END__
Archive a source.

Usage: archive.rb [--verbose] [--compress level?] source

Options:
  --verbose           Show detailed output
  --compress level?   Compress the archive, optionally at the given level
