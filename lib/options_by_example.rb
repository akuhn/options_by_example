# frozen_string_literal: true

require 'options_by_example/version'


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

  def parse(argv, settings = @settings)
    array = argv.dup
    @arguments = {}
    @options = {}

    # --- 1) Handle help option ---------------------------------------

    if @settings[:exit_on_error] and (array.include?('-h') or array.include?('--help'))
      puts @usage
      exit
    end

    # --- 1) Parse options --------------------------------------------

    most_recent_option = nil
    until array.empty? do
      break unless array.first.start_with?(?-)
      most_recent_option = option = array.shift
      option_name, argument_name = @option_names[option]
      raise "Found unknown option '#{option}'" if option_name.nil?
      @options[option_name] = true

      # Consume argument, if expected by most recent option
      if argument_name
        if array.first && array.first.start_with?(?-)
          raise "Expected argument for option '#{option}', got none"
        end
        @arguments[option_name] = array.shift
        most_recent_option = nil
      end
    end

    # --- 2) Ensure remainder are arguments ----------------------------

    array.each do |each|
      raise "Expected arguments, but found option '#{each}'" if each.start_with?(?-)
    end

    # --- 3) Validate the number of arguments -------------------------

    min_length = @argument_names_required.size
    max_length = @argument_names_optional.size + min_length
    if array.size > max_length
      range = [min_length, max_length].uniq.join(?-)
      raise "Expected #{range} arguments, but received too many"
    end

    # --- 3) Parse required arguments ---------------------------------

    stash = array.pop(@argument_names_required.length)
    @argument_names_required.each do |argument_name|
      raise "Missing required argument '#{argument_name}'" if stash.empty?
      @arguments[argument_name] = stash.shift
    end

    # --- 4) Parse optional arguments ---------------------------------

    @argument_names_optional.each do |argument_name|
      break if array.empty?
      @arguments[argument_name] = array.shift
    end

    raise "Internal error: unreachable state" unless array.empty?

    return self

  rescue RuntimeError => err
    raise unless @settings[:exit_on_error]
    puts "ERROR: #{err.message}"
    exit 1
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

