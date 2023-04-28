# Options by Example

No-code options parser that automatically detects command-line options from the usage text of your application. This intuitive parser identifies optional and required argument names as well as option names without requiring any additional code, making it easy to manage user input for your command-line applications.

Features

- Automatically detects optional and required argument names from usage text
- Automatically detects option names and associated arguments (if any) from usage text
- Parses those arguments and options from the command line (ARGV)
- Raises errors for unknown options or missing required arguments


Example

```ruby
require 'options_by_example'

Options = OptionsByExample.read(DATA).parse(ARGV)

puts Options.include_secure?
puts Options.include_verbose?
puts Options.include_retries?
puts Options.include_timeout?
puts Options.argument_retries
puts Options.argument_timeout
puts Options.argument_mode
puts Options.argument_host
puts Options.argument_port


__END__
Establishes a network connection to a designated host and port, enabling
users to assess network connectivity and diagnose potential problems.

Usage: connect [options] [mode] host port

Options:
  -s, --secure        Establish a secure connection (SSL/TSL)
  -v, --verbose       Enable verbose output for detailed information
  -r, --retries NUM   Specify the number of connection retries (default 3)
  -t, --timeout NUM   Set the connection timeout in seconds (default 10)

Arguments:
  [mode]              Optional connection mode (active or passive)
  host                The target host to connect to (e.g., example.com)
  port                The target port to connect to (e.g., 80)
```

