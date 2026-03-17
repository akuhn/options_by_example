# Options by Example

No-code options parser that automatically detects command-line options from the usage text.

Features

- Automatically infers options and argument names from usage text
- Parses those arguments and options from the command line (ARGV)
- Raises errors for unknown options or missing required arguments

Example

```ruby
require %(options_by_example)

flags = OptionsByExample.read(DATA).parse(ARGV)

puts 'Feeling verbose today' if flags.include?(:verbose)
puts flags.get(:words).sample(flags.get(:num))

__END__
Choose at random from a list of provided words.

Usage: random.rb [options] words ...

Options:
  -n, --num NUM     Number of choices (default 1)
  --verbose         Enable verbose mode
```

And then call the program with eg

    ruby random.rb -n 2 foo bar qux

### Installation

To use options_by_example, first install the gem by running:

```
gem install options_by_example
```

Alternatively, add this line to your Gemfile and run bundle install:

```
gem 'options_by_example'
```

