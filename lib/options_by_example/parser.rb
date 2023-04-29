# frozen_string_literal: true


class OptionsByExample
  class Parser

    attr_reader :options
    attr_reader :arguments

    def initialize(settings, option_names, argument_names_optional, argument_names_required)
      @settings = settings
      @option_names = option_names
      @argument_names_optional = argument_names_optional
      @argument_names_required = argument_names_required

      @arguments = {}
      @options = {}
    end

    def parse(array)
      @array = array.dup

      handle_help_option
      parse_options
      ensure_remainder_are_arguments
      validate_number_of_arguments
      parse_required_arguments
      parse_optional_arguments

      raise "Internal error: unreachable state" unless @array.empty?
    rescue RuntimeError => err
      raise unless @settings[:exit_on_error]
      puts "ERROR: #{err.message}"
      exit 1
    end

    private

    def handle_help_option
      if @settings[:exit_on_error] and (@array.include?('-h') or @array.include?('--help'))
        puts @usage
        exit
      end
    end

    def parse_options
      until @array.empty? do
        break unless @array.first.start_with?(?-)
        most_recent_option = option = @array.shift
        option_name, argument_name = @option_names[option]
        raise "Found unknown option '#{option}'" if option_name.nil?
        @options[option_name] = true

        # Consume argument, if expected by most recent option
        if argument_name
          if @array.first && @array.first.start_with?(?-)
            raise "Expected argument for option '#{option}', got none"
          end
          @arguments[option_name] = @array.shift
        end
      end
    end

    def ensure_remainder_are_arguments
      @array.each do |each|
        raise "Expected arguments, but found option '#{each}'" if each.start_with?(?-)
      end
    end

    def validate_number_of_arguments
      min_length = @argument_names_required.size
      max_length = @argument_names_optional.size + min_length
      if @array.size > max_length
        range = [min_length, max_length].uniq.join(?-)
        raise "Expected #{range} arguments, but received too many"
      end
    end

    def parse_required_arguments
      stash = @array.pop(@argument_names_required.length)
      @argument_names_required.each do |argument_name|
        raise "Missing required argument '#{argument_name}'" if stash.empty?
        @arguments[argument_name] = stash.shift
      end
    end

    def parse_optional_arguments
      @argument_names_optional.each do |argument_name|
        break if @array.empty?
        @arguments[argument_name] = @array.shift
      end
    end
  end
end
