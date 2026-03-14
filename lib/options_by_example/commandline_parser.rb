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
      @option_names = usage.option_names

      @argument_values = {}
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

      exit_if_help_option
      unpack_combined_shorthand_options
      expand_dash_number_to_dash_n_option
      raise_if_unknown_options
      parse_options
      coerce_num_date_time_etc

      validate_number_of_arguments
      parse_positional_arguments

      # :nocov:
      raise %{unreachable given we check number of arguments} unless @remainder.empty?
      # :nocov:
    end

    private

    def exit_if_help_option
      @slices.each do |option, *args|
        case option
        when '-h', '--help'
          if args.first == 'debug!'
            puts "@argument_names = #{@argument_names.inspect}"
            puts "@option_names = #{@option_names.inspect}"
          end
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

        option_name, has_argument, ___ = @option_names[option]
        @option_values[option_name] = true

        if has_argument
          raise "Expected argument for option '#{option}', got none" if args.empty?
          @argument_values[option_name] = args.shift
          @option_took_argument = option
        else
          @option_took_argument = nil
        end

        @remainder = args
      end
    end

    def coerce_num_date_time_etc
      @option_names.each do |option, (each, argument_name, default_value)|
        value = @argument_values.fetch(each, default_value)
        next unless value

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

        @argument_values[each] = value
      end
    end

    def validate_number_of_arguments
      # ASSUME: either varargs or optional arguments, never both. That
      # constraint is guaranteed upstream. Here, we just count

      min_length = count_arguments(:required) + count_arguments(:vararg)
      max_length = count_arguments(:required) + count_arguments(/optional/)
      max_length = nil if count_arguments(/vararg/) > 0

      unless (min_length..max_length) === @remainder.size

        if max_length.nil?
          msg = "Expected #{min_length} or more arguments,"
        elsif max_length > min_length
          msg = "Expected #{min_length}-#{max_length} arguments,"
        else
          msg = "Expected #{min_length} arguments,"
        end

        if @remainder.empty?
          msg += " but received none"
        elsif @remainder.size == 1 && min_length > 1
          msg += " but received only one"
        elsif @remainder.size < min_length
          msg += " but received too few"
        elsif max_length && @remainder.size > max_length
          msg += " but received too many"
        # :nocov:
        else
          raise %{unreachable given the range check above}
        # :nocov:
        end

        if @option_took_argument
          msg += " (considering #{@option_took_argument} takes an argument)"
        end

        raise msg
      end
    end

    def parse_positional_arguments
      remaining_arguments = @argument_names.length
      @argument_names.each do |argument_name, arity|
        remaining_arguments -= 1
        case arity
        when :required
          @argument_values[argument_name] = @remainder.shift
        when :vararg, :optional_vararg
          @argument_values[argument_name] = @remainder.shift(@remainder.length - remaining_arguments)
        when :optional
          next if @remainder.empty?
          @argument_values[argument_name] = @remainder.shift
        # :nocov:
        else
          raise %{unreachable given these are all possible values}
        # :nocov:
        end
      end
    end

    private

    def count_arguments(pattern)
      @argument_names.values.grep(pattern).count
    end
  end
end
