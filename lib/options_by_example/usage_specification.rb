# frozen_string_literal: true

class OptionsByExample

  class UsageSpecification

    attr_reader :message
    attr_reader :argument_names
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
      raise "Expected usage string, got none" unless usage_line
      tokens = usage_line.scan(/\[.*?\]|\w+ \.\.\.|\S+/)
      raise "Expected usage line to start with 'Usage:'" unless tokens.shift == 'Usage:'
      raise "Expected command name on same line as 'Usage:'" unless tokens.shift
      tokens.shift if tokens.first == '[options]'

      while /^\[(--?\w.*)\]$/ === tokens.first
        inline_options << $1
        tokens.shift
      end

      while /^(\w+)( ?\.\.\.)?$/ === tokens.first
        vararg_if_dotted = $2 ? :vararg : :required
        @argument_names[sanitize $1] = vararg_if_dotted
        tokens.shift
      end

      while /^\[(\w+)\]$/ === tokens.first
        @argument_names[sanitize $1] = :optional
        tokens.shift
      end

      if /^\[(\w+) ?\.\.\.\]$/ === tokens.first
        @argument_names[sanitize $1] = :optional_vararg
        tokens.shift
      end

      raise "Found invalid usage token '#{tokens.first}'" unless tokens.empty?

      if count_arguments(:vararg) > 0 && count_arguments(/optional/) > 0
        raise "Cannot combine vararg and optional arguments"
      end

      if count_arguments(/vararg/) > 1
        raise "Found more than one vararg arguments"
      end

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

        ary = [option_name, argument_name, default_value]
        [short_form, long_form].each do |each|
          @option_names[each] = ary if each
        end
      end
    end

    private

    def sanitize(string)
      string.tr('^a-zA-Z0-9', '_').downcase.to_sym
    end

    def count_arguments(pattern)
      @argument_names.values.grep(pattern).count
    end
  end
end
