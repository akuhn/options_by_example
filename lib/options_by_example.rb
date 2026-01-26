# frozen_string_literal: true

require 'options_by_example/version'
require 'options_by_example/commandline_parser'
require 'options_by_example/usage_specification'


class OptionsByExample

  attr_reader :arguments
  attr_reader :options
  attr_reader :usage_spec

  def self.read(data)
    return new data.read
  end

  def initialize(text)
    @usage_spec = UsageSpecification.new(text)

    initialize_argument_accessors
    initialize_option_accessors
  end

  def parse(argv)
    parse_without_exit argv
  rescue PrintUsageMessage
    puts @usage_spec.message
    exit 0
  rescue RuntimeError => err
    puts "ERROR: #{err.message}"
    exit 1
  end

  def fetch(*args, &block)
    @arguments.fetch(*args, &block)
  end

  def get(name)
    @arguments[name]
  end

  def if_present(name)
    raise ArgumentError, 'block missing' unless block_given?

    value = @arguments[name]
    value.nil? ? value : (yield value)
  end

  def include?(name)
    @options.include?(name)
  end

  private

  def parse_without_exit(argv)
    parser = CommandlineParser.new(@usage_spec)
    parser.parse(argv)

    @arguments = parser.argument_values
    @options = parser.option_values

    return self
  end

  def initialize_argument_accessors
    [
      *@usage_spec.argument_names_required,
      *@usage_spec.argument_names_optional,
      *@usage_spec.option_names.values.select(&:last).map(&:first),
    ].each do |argument_name|
      instance_eval %{
        def argument_#{argument_name}
          val = @arguments[:#{argument_name}]
          val && block_given? ? (yield val) : val
        end
      }
    end
  end

  def initialize_option_accessors
    @usage_spec.option_names.each_value do |option_name, _|
      instance_eval %{
        def include_#{option_name}?
          @options.include? :#{option_name}
        end
      }
    end
  end
end

