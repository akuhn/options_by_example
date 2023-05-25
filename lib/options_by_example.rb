# frozen_string_literal: true

require 'options_by_example/options'
require 'options_by_example/parser'
require 'options_by_example/version'


class OptionsByExample

  attr_reader :option_names
  attr_reader :default_values
  attr_reader :argument_names_optional
  attr_reader :argument_names_required

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
  end

  def parse(argv)
    values = Parser.new(self).parse(argv)
    Options.new self, values
  rescue PrintUsageMessage
    puts @usage_message
    exit 0
  rescue RuntimeError => err
    puts "ERROR: #{err.message}"
    exit 1
  end

  def parse_and_extend(argv)
    options = parse(argv)

    # NOTE: This code extends ARGV to provide convenient access to parsed
    # options in cases where the gem may not be loaded. It patches the #[]
    # and #include? methods of ARGV respond as if it where both an array
    # of strings (as usual) and a hash of symbolized option names mapping
    # to their values. For example, by calling ARGV.include?(:verbose) we
    # can safely check for the presence of the "verbose" option regardless
    # of whether the gem has been loaded or not.

    argv.instance_variable_set :@options_by_example, options.to_h
    argv.extend Extension

    return options
  end

  module Extension
    def include?(arg)
      @options_by_example.include?(arg) or super
    end

    def [](arg, *args)
      Symbol === arg ? @options_by_example[arg] : super
    end

    def fetch(*args, &block)
      Symbol === arg ? @options_by_example.fetch(*args, &block) : super
    end
  end

  private

  def sanitize(str)
    str.tr('-', '_').downcase.to_sym
  end
end

