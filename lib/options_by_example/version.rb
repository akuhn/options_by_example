# frozen_string_literal: true

class OptionsByExample
  VERSION = '3.1.0-bis'
end


__END__

# Major version bump when breaking changes or new features
# Minor version bump when backward-compatible changes or enhancements
# Patch version bump when backward-compatible bug fixes, security updates etc

3.1.0-bis

  - Support dash in option names

3.0.0

  - Support options with default values
  - Improved support for one-line usage messages
  - Expand combined shorthand options into their separate components
  - Shorthand options must be single letter only

2.0.0

  - Replaced dynamic methods with explicit methods for options and arguments
  - Removed ability to call dynamic methods with undeclared names

1.3.0

  - Extracted parsing functionality into class
  - Better error messages

1.2.0

  - Ensure compatibility with Ruby versions 1.9.3 and newer

1.1.0

  - Renamed the gem from usage_by_example to options_by_example
  - Update the gemspec to include readme and ruby files only
  - Update readme file with features and an example

1.0.0

  - Extract optional and required argument names from a usage text
  - Extract option names and associated argument names (if any) from a usage text
  - Include help option by default
  - Parse options and arguments from command-line arguments aka ARGV
  - Exit gracefully or raise exceptions, depending on the exit_on_error parameter
  - Implement dynamic methods for checking options and getting arguments
  - Ensure correct git tag and all changes committed when building gem

0.0.0

  - Prehistory starts here...
