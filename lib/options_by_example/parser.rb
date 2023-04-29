# frozen_string_literal: true


class OptionsByExample
  class Parser

    attr_reader :options
    attr_reader :arguments

    def initialize(argument_names_required, argument_names_optional, option_names)
      @argument_names_required = argument_names_required
      @argument_names_optional = argument_names_optional
      @option_names = option_names

      @arguments = {}
      @options = {}
    end

    def parse(array)

      # Separate command-line options and their respective arguments into
      # chunks plus handling any remaining arguments. This organization
      # facilitates further processing and validation of the input.

      @chunks = array.slice_before { |each| each.start_with?(?-) }.entries
      @remainder = @chunks.pop || []
      if @remainder && @remainder.first && @remainder.first.start_with?(?-)
        option_name, argument_name = @option_names[@remainder.first]
        @chunks.push @remainder.shift(argument_name ? 2 : 1)
      end

      # Detect unexpected arguments, error will be raised later in the
      # parse_options method so refer to proceeding option name.

      if @chunks.any? && !@chunks.first.first.start_with?(?-)
        @unexpected_args = @chunks.shift
      end

      find_help_option
      find_unknown_options
      parse_options

      validate_number_of_arguments
      parse_required_arguments
      parse_optional_arguments

      raise "Internal error: unreachable state" unless @remainder.empty?
      raise "Internal error: unreachable state" if @unexpected_args
    end

    private

    def find_help_option
      @chunks.each do |option, *args|
        case option
        when '-h', '--help'
          raise "puts @usage_message"
        end
      end
    end

    def find_unknown_options
      @chunks.each do |option, *args|
        raise "Found unknown option '#{option}'" unless @option_names.include?(option)
      end
    end

    def parse_options
      @chunks.each do |option, *args|
        if @unexpected_args
          raise "Unexpected arguments found before option '#{option}', please provide all options before arguments"
        end

        option_name, argument_name = @option_names[option]
        @options[option_name] = true
        if argument_name
          raise "Expected argument for option '#{option}', got none" if args.empty?
          @arguments[option_name] = args.shift
        end
        @unexpected_args = args.any?
      end
    end

    def validate_number_of_arguments
      min_length = @argument_names_required.size
      max_length = @argument_names_optional.size + min_length
      if @remainder.size > max_length
        range = [min_length, max_length].uniq.join(?-)
        raise "Expected #{range} arguments, but received too many"
      end
    end

    def parse_required_arguments
      stash = @remainder.pop(@argument_names_required.length)
      @argument_names_required.each do |argument_name|
        raise "Missing required argument '#{argument_name}'" if stash.empty?
        @arguments[argument_name] = stash.shift
      end
    end

    def parse_optional_arguments
      @argument_names_optional.each do |argument_name|
        break if @remainder.empty?
        @arguments[argument_name] = @remainder.shift
      end
    end
  end
end