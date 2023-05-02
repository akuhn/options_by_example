# frozen_string_literal: true


class OptionsByExample

  class PrintUsageMessage < StandardError
  end

  class Parser

    attr_reader :options
    attr_reader :arguments

    def initialize(argument_names_required, argument_names_optional, default_values, option_names)
      @argument_names_required = argument_names_required
      @argument_names_optional = argument_names_optional
      @default_values = default_values
      @option_names = option_names

      @arguments = @default_values.dup
      @options = {}
    end

    def parse(array)

      # Separate command-line options and their respective arguments into
      # chunks, plus tracking leading excess arguments. This organization
      # facilitates further processing and validation of the input.

      @chunks = []
      @remainder = current = []
      array.each do |each|
        @chunks << current = [] if each.start_with?(?-)
        current << each
      end

      detect_help_option
      flatten_stacked_shorthand_options
      detect_unknown_options
      parse_options

      validate_number_of_arguments
      parse_required_arguments
      parse_optional_arguments

      raise "Internal error: unreachable state" unless @remainder.empty?
    end

    private

    def detect_help_option
      @chunks.each do |option, *args|
        case option
        when '-h', '--help'
          raise PrintUsageMessage
        end
      end
    end

    def flatten_stacked_shorthand_options

      # Expand any combined shorthand options like -svt into their
      # separate components (-s, -v, and -t) and assigns any arguments
      # to the last component. If an unknown shorthand is found, raise
      # a helpful error message with suggestion if possible.

      list = []
      @chunks.each do |option, *args|
        if option =~ /^-([a-zA-Z]{2,})$/
          shorthands = $1.each_char.map { |char| "-#{char}" }

          shorthands.each do |each|
            if not @option_names.include?(each)
              did_you_mean = ", did you mean '-#{option}'?" if @option_names.include?("-#{option}")
              raise "Found unknown option #{each} inside '#{option}'#{did_you_mean}"
            end
          end

          list.concat shorthands.map { |each| [each] }
          list.last.concat args
        else
          list << [option, *args]
        end
      end

      @chunks = list
    end

    def detect_unknown_options
      @chunks.each do |option, *args|
        raise "Found unknown option '#{option}'" unless @option_names.include?(option)
      end
    end

    def parse_options
      @chunks.each do |option, *args|
        if @remainder.any?
          raise "Unexpected arguments found before option '#{option}', please provide all options before arguments"
        end

        option_name, argument_name = @option_names[option]
        @options[option_name] = true

        if argument_name
          raise "Expected argument for option '#{option}', got none" if args.empty?
          @arguments[option_name] = args.shift
          @option_took_argument = option
        else
          @option_took_argument = nil
        end

        @remainder = args
      end
    end

    def validate_number_of_arguments
      min_length = @argument_names_required.size
      max_length = @argument_names_optional.size + min_length

      if @remainder.size > max_length
        range = [min_length, max_length].uniq.join(?-)
        raise "Expected #{range} arguments, but received too many"
      end

      if @remainder.size < min_length
        too_few = @remainder.empty? ? 'none' : (@remainder.size == 1 ? 'only one' : 'too few')
        remark = " (considering #{@option_took_argument} takes an argument)" if @option_took_argument
        raise "Expected #{min_length} required arguments, but received #{too_few}#{remark}"
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
