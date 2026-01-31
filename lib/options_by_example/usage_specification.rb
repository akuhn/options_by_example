# frozen_string_literal: true

class OptionsByExample

  class UsageSpecification

    attr_reader :message
    attr_reader :argument_names
    attr_reader :default_values
    attr_reader :option_names

    def initialize(text)
      @message = text.gsub('$0', File.basename($0)).gsub(/\n+\Z/, "\n\n")

      # --- 1) Parse argument names -------------------------------------
      #
      # Parse the usage string and extract both optional argument names
      # and required argument names, for example:
      #
      # Usage: connect [options] [mode] host port

      @argument_names = {}
      inline_options = []

      usage_line = text.lines.grep(/Usage:/).first
      raise RuntimeError, "Expected usage string, got none" unless usage_line
      tokens = usage_line.scan(/\[.*?\]|\S+/)
      raise unless tokens.shift
      raise unless tokens.shift
      tokens.shift if tokens.first == '[options]'

      while /^\[(--?\w.*)\]$/ === tokens.first
        inline_options << (tokens.shift && $1)
      end

      while /^\[(\w+)\]$/ === tokens.first
        @argument_names[sanitize tokens.shift && $1] = :optional
      end

      while /^(\w+)\.\.\.$/ === tokens.first
        @argument_names[sanitize tokens.shift && $1] = :repeated
      end

      while /^(\w+)$/ === tokens.first
        @argument_names[sanitize tokens.shift && $1] = :required
      end

      while /^(\w+)\.\.\.$/ === tokens.first
        @argument_names[sanitize tokens.shift && $1] = :repeated
      end

      raise unless tokens.empty?

      count_optional_arguments = @argument_names.values.count(:optional)
      count_vararg_arguments = @argument_names.values.count(:repeated)

      raise if count_optional_arguments > 0 && count_vararg_arguments > 0
      raise if count_vararg_arguments > 1

      # --- 2) Parse option names ---------------------------------------
      #
      # Parse the usage message and extract option names, their short and
      # long forms, and the associated argument name (if any), eg:
      #
      # Options:
      #   -s, --secure        Use secure connection
      #   -v, --verbose       Enable verbose output
      #   -r, --retries NUM   Number of connection retries (default 3)
      #   -t, --timeout NUM   Set connection timeout in seconds

      @option_names = {}
      @default_values = {}

      options = inline_options + text.lines.grep(/^\s*--?\w/)
      options.each do |string|
        tokens = string.scan(/--?\w[\w-]*(?: \w+)?|,|\(default \S+\)|\S+/)

        short_form = nil
        long_form = nil
        option_name = nil
        argument_name = nil
        default_value = nil

        if /^-(\w)( \w+)?$/ === tokens.first
          short_form, argument_name = tokens.shift.split
          option_name = sanitize $1
          tokens.shift if ',' === tokens.first
        end

        if /^--([\w-]+)( \w+)?$/ === tokens.first
          long_form, argument_name = tokens.shift.split
          option_name = sanitize $1
        end

        if /^\(default (\S+)\)$/ === tokens.last
          default_value = $1
        end

        [short_form, long_form].compact.each do |each|
          @option_names[each] = [option_name, argument_name]
        end

        @default_values[option_name] = default_value if default_value
      end
    end

    private

    def sanitize(string)
      string.tr('^a-zA-Z0-9', '_').downcase.to_sym
    end
  end
end
