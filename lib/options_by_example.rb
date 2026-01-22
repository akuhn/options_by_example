# frozen_string_literal: true

require 'options_by_example/version'
require 'options_by_example/parser'


class OptionsByExample

  attr_reader :arguments
  attr_reader :usage_message

  def self.read(data)
    return new data.read
  end

  def initialize(text)
    @usage_message = text.gsub('$0', File.basename($0)).gsub(/\n+\Z/, "\n\n")

    # --- 1) Parse argument names -------------------------------------
    #
    # Parse the usage string and extract both optional argument names
    # and required argument names, for example:
    #
    # Usage: connect [options] [mode] host port

    text =~ /Usage: (\$0|\w+)(?: \[options\])?((?: \[\w+\])*)((?: \w+)*)/
    raise RuntimeError, "Expected usage string, got none" unless $1
    @argument_names_optional = $2.to_s.split.map { |match| sanitize match.tr('[]', '') }
    @argument_names_required = $3.to_s.split.map { |match| sanitize match }

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
    text.scan(/(?:(-\w), ?)?(--([\w-]+))(?: (\w+))?(?:.*\(default:? (\w+)\))?/) do
      flags = [$1, $2].compact
      flags.each { |each| @option_names[each] = [(sanitize $3), $4] }
      @default_values[sanitize $3] = $5 if $5
    end

    initialize_argument_accessors
    initialize_option_accessors
  end

  def parse(argv)
    parse_without_exit argv
  rescue PrintUsageMessage
    puts @usage_message
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
    @arguments.include?(name)
  end

  private

  def parse_without_exit(argv)
    parser = Parser.new(
      @argument_names_required,
      @argument_names_optional,
      @default_values,
      @option_names,
    )

    @arguments = parser.parse(argv)

    return self
  end

  def initialize_argument_accessors
    [
      *@argument_names_required,
      *@argument_names_optional,
      *@option_names.values.select(&:last).map(&:first),
    ].each do |argument_name|
      instance_eval %{
        def get_#{argument_name}
          val = @arguments[:#{argument_name}]
          val && block_given? ? (yield val) : val
        end
      }
    end
  end

  def initialize_option_accessors
    @option_names.each_value do |option_name, _|
      instance_eval %{
        def include_#{option_name}?
          @arguments.include? :#{option_name}
        end
      }
    end
  end

  def sanitize(string)
    string.tr('^a-zA-Z0-9', '_').downcase.to_sym
  end
end

