# frozen_string_literal: true

class OptionsByExample
  VERSION = '1.1.0'
end


__END__

# Major version bump when breaking changes or new features
# Minor version bump when backward-compatible changes or enhancements
# Patch version bump when backward-compatible bug fixes, security updates etc

1.0.1

  - Update readme file with features and an example
  - Update the gemspec to include readme and ruby files only

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