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
    @usage = text.gsub('$0', File.basename($0)).gsub(/\n+\Z/, "\n\n")

    # ---- 1) Parse argument names ------------------------------------
    #
    # Parse the usage string and extract both optional argument names
    # and required argument names, for example:
    #
    # Usage: connect [options] [mode] host port

    text =~ /Usage: (\w+|\$0) \[options\](( \[\w+\])*)(( \w+)*)/
    raise RuntimeError, "Expected usage string, got none" unless $1
    @argument_names_optional = $2.to_s.split.map { |match| match.tr('[]', '').downcase }
    @argument_names_required = $4.to_s.split.map(&:downcase)

    # ---- 2) Parse option names --------------------------------------
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

    # ---- 3) Include help option by default --------------------------

    @option_names.update("-h" => :help, "--help" => :help)
  end

  def parse(argv, options = nil)
    array = argv.dup
    @arguments = {}
    @options = {}

    # --- 1) Parse options --------------------------------------------

    most_recent_option = nil
    until array.empty? do
      break unless array.first.start_with?(?-)
      most_recent_option = option = array.shift
      option_name, argument_name = @option_names[option]
      raise "Got unknown option #{option}" if option_name.nil?
      raise if option_name == :help # Show usage without error message
      @options[option_name] = true

      # Consume argument, if expected by most recent option
      if argument_name
        argument = array.shift
        raise "Expected argument for option #{option}" unless /^[^-]/ === argument
        @arguments[option_name] = argument
        most_recent_option = nil
      end
    end

    # --- 2) Parse optional arguments ---------------------------------

    # Check any start with --, ie excess options
    # Check min_length - max_length here

    stash = array.pop(@argument_names_required.length)
    @argument_names_optional.each do |argument_name|
      break if array.empty?
      argument = array.shift
      raise "Expected more arguments, got option #{option}" unless /^[^-]/ === argument
      @arguments[argument_name] = argument
    end

    # --- 3) Parse required arguments ---------------------------------

    @argument_names_required.each do |argument_name|
      raise "Expected required argument #{argument_name.upcase}, got none" if stash.empty?
      argument = stash.shift
      raise "Expected more arguments, got option #{option}" unless /^[^-]/ === argument
      @arguments[argument_name] = argument
    end

    # --- 4) Expect to be done ----------------------------------------

    if not array.empty?
      # Custom error message if most recent option did not require argument
      raise "Got unexpected argument for option #{most_recent_option}" if most_recent_option
      min_length = @argument_names_required.size
      max_length = @argument_names_optional.size + min_length
      raise "Expected #{min_length}#{"-#{max_length}" if max_length > min_length} arguments, got more"
    end

    return self

  rescue RuntimeError => err
    exit_on_error = options ? options[:exit_on_error] : true
    if exit_on_error
      puts "ERROR: #{err.message}\n\n" unless err.message.empty?
      puts @usage
      exit
    else
      raise # Reraise the same exception
    end
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

