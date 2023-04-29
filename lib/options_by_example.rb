# frozen_string_literal: true

require 'options_by_example/version'
require 'options_by_example/parser'


class OptionsByExample

  attr_reader :argument_names_optional
  attr_reader :argument_names_required
  attr_reader :option_names

  attr_reader :arguments
  attr_reader :options


  def self.read(data)
    return new data.read
  end

  def initialize(text)
    @settings = {exit_on_error: true}
    @usage = text.gsub('$0', File.basename($0)).gsub(/\n+\Z/, "\n\n")

    # --- 1) Parse argument names -------------------------------------
    #
    # Parse the usage string and extract both optional argument names
    # and required argument names, for example:
    #
    # Usage: connect [options] [mode] host port

    text =~ /Usage: (\w+|\$0)( \[options\])?(( \[\w+\])*)(( \w+)*)/
    raise RuntimeError, "Expected usage string, got none" unless $1
    @argument_names_optional = $3.to_s.split.map { |match| match.tr('[]', '').downcase }
    @argument_names_required = $5.to_s.split.map(&:downcase)

    # --- 2) Parse option names ---------------------------------------
    #
    # Parse the usage message and extract option names, their short and
    # long forms, and the associated argument name (if any), eg:
    #
    # Options:
    #   -s, --secure        Use secure connection
    #   -v, --verbose       Enable verbose output
    #   -r, --retries NUM   Number of connection retries (default 3)
    #   -t, --timeout NUM   Connection timeout in seconds (default 10)

    @option_names = {}
    text.scan(/((--?\w+)(, --?\w+)*) ?(\w+)?/) do
      opts = $1.split(", ")
      opts.each { |each| @option_names[each] = [opts.last.tr('-', ''), ($4.downcase if $4)] }
    end
  end

  def use(settings)
    @settings.update settings

    return self
  end

  def parse(argv)
    parser = Parser.new(
      @settings,
      @option_names,
      @argument_names_optional,
      @argument_names_required,
    )

    parser.parse argv

    @options = parser.options
    @arguments = parser.arguments

    return self
  end


  def method_missing(sym, *args, &block)
    case sym
    when /^argument_(\w+)$/
      val = @arguments[$1]
      block && val ? block.call(val) : val
    when /^include_(\w+)\?$/
      @options[$1]
    else
      super
    end
  end
end

