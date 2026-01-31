# frozen_string_literal: true

require 'date'
require 'time'


class OptionsByExample

  class PrintUsageMessage < StandardError
  end

  class CommandlineParser

    attr_reader :option_values
    attr_reader :argument_values

    def initialize(usage)
      @argument_names = usage.argument_names
      @default_values = usage.default_values
      @option_names = usage.option_names

      @argument_values = @default_values.dup
      @option_values = {}
    end

    def parse(array)

      # Separate command-line options and their respective arguments into
      # chunks, plus tracking leading excess arguments. This organization
      # facilitates further processing and validation of the input.

      @slices = []
      @remainder = current = []
      array.each do |each|
        @slices << current = [] if each.start_with?(?-)
        current << each
      end

      raise_if_help_option
      unpack_combined_shorthand_options
      expand_dash_number_to_dash_n_option
      raise_if_unknown_options
      parse_options

      validate_number_of_arguments
      parse_required_arguments
      parse_optional_arguments

      raise "Internal error: unreachable state" unless @remainder.empty?
    end

    private

    def raise_if_help_option
      @slices.each do |option, *args|
        case option
        when '-h', '--help'
          raise PrintUsageMessage
        end
      end
    end

    def unpack_combined_shorthand_options

      # Expand any combined shorthand options like -svt into their
      # separate components (-s, -v, and -t) and assigns any arguments
      # to the last component. If an unknown shorthand is found, raise
      # a helpful error message with suggestion if possible.

      list = []
      @slices.each do |option, *args|
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

      @slices = list
    end

    def expand_dash_number_to_dash_n_option
      @slices.each do |each|
        if each.first =~ /^-(\d+)$/
          each[0..0] = ['-n', $1]
        end
      end
    end

    def raise_if_unknown_options
      @slices.each do |option, *args|
        raise "Found unknown option '#{option}'" unless @option_names.include?(option)
      end
    end

    def parse_options
      @slices.each do |option, *args|
        if @remainder.any?
          raise "Unexpected arguments found before option '#{option}', please provide all options before arguments"
        end

        option_name, argument_name = @option_names[option]
        @option_values[option_name] = true

        if argument_name
          raise "Expected argument for option '#{option}', got none" if args.empty?
          value = args.shift

          begin
            case argument_name
            when 'NUM'
              expected_type = 'an integer value'
              value = Integer value
            when 'DATE'
              expected_type = 'a date (e.g. YYYY-MM-DD)'
              value = Date.parse value
            when 'TIME'
              expected_type = 'a timestamp (e.g. HH:MM:SS)'
              value = Time.parse value
            end
          rescue ArgumentError
            raise "Invalid argument \"#{value}\" for option '#{option}', please provide #{expected_type}"
          end

          @argument_values[option_name] = value
          @option_took_argument = option
        else
          @option_took_argument = nil
        end

        @remainder = args
      end
    end

    def validate_number_of_arguments
      count_optional_arguments = @argument_names.values.count(:optional)
      count_required_arguments = @argument_names.values.count(:required)
      count_vararg_arguments = @argument_names.values.count(:vararg)

      min_length = count_required_arguments + count_vararg_arguments
      max_length = count_required_arguments + count_optional_arguments

      if @remainder.size > max_length && count_vararg_arguments == 0
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
      if @argument_names.values.include?(:vararg)
        remaining_arguments = @argument_names.length
        @argument_names.each do |argument_name, arity|
          raise "unreachable" if @remainder.empty?
          remaining_arguments -= 1
          case arity
          when :required
            @argument_values[argument_name] = @remainder.shift
          when :vararg
            @argument_values[argument_name] = @remainder.shift(@remainder.length - remaining_arguments)
          else
            raise "unreachable"
          end
        end
        return
      end

      @argument_names.reverse_each do |argument_name, arity|
        break if arity == :optional
        raise "unreachable" if @remainder.empty?
        @argument_values[argument_name] = @remainder.pop
      end
    end

    def parse_optional_arguments
      @argument_names.each do |argument_name, arity|
        break unless arity == :optional
        break if @remainder.empty?
        @argument_values[argument_name] = @remainder.shift
      end
    end
  end
end
