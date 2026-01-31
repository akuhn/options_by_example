# frozen_string_literal: true
require 'options_by_example'


describe OptionsByExample do

  it 'has a version number' do
    expect(OptionsByExample::VERSION).not_to be nil
  end

  it 'reads and parses options from DATA and ARGV' do
    ARGV.clear.concat %w{--secure example.com 443}
    DATA = StringIO.new usage_message
    Options = OptionsByExample.read(DATA).parse(ARGV)

    expect(Options.include_secure?).to be true
    expect(Options.argument_host).to eq 'example.com'
    expect(Options.argument_port).to eq '443'
  end

  it 'supports one-line usage messages' do
    usage = 'Usage: $0 [-v,--verbose] [-i,--interactive]'
    this = OptionsByExample.new(usage).parse(%w{-v})

    expect(this.include_verbose?).to be true
    expect(this.include_interactive?).to be false
  end

  it 'supports one-line usage messages with positional arguments' do
    usage = 'Usage: connect [-s, --secure] [mode] host port'
    this = OptionsByExample.new(usage).parse(%w{-s passive example.com 80})

    expect(this.include_secure?).to be true
    expect(this.argument_mode).to eq 'passive'
  end

  it 'supports shorthand-only option' do
    usage = 'Usage: convert [-q] [-d] [-r] fname'

    this = OptionsByExample
      .new(usage)
      .parse(%w{-r example.png})

    expect(this.include_r?).to be true
    expect(this.argument_fname).to eq 'example.png'
  end

  it 'supports shorthand-only option with argument' do
    usage = 'Usage: head [-n NUM] fname'
    this = OptionsByExample.new(usage).parse(%w{-n 20 example.md})

    expect(this.argument_n).to eq 20
    expect(this.argument_fname).to eq 'example.md'
  end

  it 'supports shorthand-only option with default value' do
    usage = 'Usage: head [-n NUM (default 10)] fname'
    this = OptionsByExample.new(usage).parse(%w{example.md})

    expect(this.argument_n).to eq '10'
    expect(this.argument_fname).to eq 'example.md'
  end

  it 'supports trailing vararg arguments' do
    usage = 'Usage: archive zipfile files...'
    this = OptionsByExample.new(usage).parse(%w{example foo bar})

    expect(this.argument_zipfile).to eq 'example'
    expect(this.argument_files).to eq ['foo', 'bar']
  end

  it 'supports leading vararg arguments' do
    usage = 'Usage: join sources... dest'
    this = OptionsByExample.new(usage).parse(%w{foo bar example})

    expect(this.argument_sources).to eq ['foo', 'bar']
    expect(this.argument_dest).to eq 'example'
  end

  let(:usage_message) {
    %{
      Establishes network connection to designated host and port, enabling
      users to assess network connectivity and diagnose potential issues.

      Usage: connect [options] [mode] host port

      Options:
        -s, --secure        Establish a secure connection (SSL/TSL)
        -v, --verbose       Enable verbose output for detailed information
        -r, --retries ARG   Number of connection retries (default 3)
        -t, --timeout ARG   Set connection timeout in seconds

      Arguments:
        [mode]              Optional connection mode (active or passive)
        host                The target host to connect to (e.g., example.com)
        port                The target port to connect to (e.g., 80)
    }
  }

  let(:this) { OptionsByExample.new(usage_message) }

  describe "#initialize" do

    it 'parses argument names' do
      argument_names = this.usage_spec.argument_names
      expect(argument_names).to include mode: :optional
      expect(argument_names).to include host: :required
      expect(argument_names).to include port: :required
      expect(argument_names.size).to be 3
    end

    it 'parses all options' do
      option_names = this.usage_spec.option_names
      expect(option_names['-v']).to eq [:verbose, nil]
      expect(option_names['--verbose']).to eq [:verbose, nil]
      expect(option_names['--retries']).to eq [:retries, "ARG"]
      expect(option_names.size).to be 8
    end

    it 'parses default values' do
      default_values = this.usage_spec.default_values
      expect(default_values[:retries]).to eq "3"
      expect(default_values.size).to be 1
    end
  end

  describe 'custom accessor methods' do

    it 'responds to positional arguments' do
      expect(this).to respond_to :argument_mode
      expect(this).to respond_to :argument_port
      expect(this).to respond_to :argument_host
    end

    it 'responds to options' do
      expect(this).to respond_to :include_verbose?
      expect(this).to respond_to :include_secure?
    end

    it 'responds to options with arguments' do
      expect(this).to respond_to :include_retries?
      expect(this).to respond_to :include_timeout?
      expect(this).to respond_to :argument_retries
      expect(this).to respond_to :argument_timeout
    end

    it 'supports dash in option names' do
      usage = 'Usage: $0 [--find-matches] [--enable-feature NAME]'
      this = OptionsByExample.new(usage)

      expect(this).to respond_to :include_find_matches?
      expect(this).to respond_to :include_enable_feature?
      expect(this).to respond_to :argument_enable_feature
    end

    it 'supports dash in argument names' do
      usage = 'Usage: $0 [options] BLOCK_NUMBER'
      this = OptionsByExample.new(usage)

      expect(this).to respond_to :argument_block_number
    end
  end

  describe "#include_NAME?" do

    it 'returns option status' do
      this.parse %w{-v --timeout 60 example.com 80}

      expect(this.include_verbose?).to be true
      expect(this.include_retries?).to be_falsey
      expect(this.include_secure?).to be_falsey
      expect(this.include_timeout?).to be true
    end
  end

  describe "#argument_NAME" do

    it 'returns positional argument values' do
      this.parse %w{-v --retries 5 example.com 80}

      expect(this.argument_mode).to be_nil
      expect(this.argument_host).to eq "example.com"
      expect(this.argument_port).to eq "80"
    end

    it 'returns optional argument values' do
      this.parse %w{-v --retries 5 example.com 80}

      expect(this.argument_retries).to eq "5"
      expect(this.argument_timeout).to be_nil
    end

    it 'passes arguments through block' do
      this.parse %w{-v --retries 5 example.com 80}

      expect(this.argument_retries { |val| val * 3 }).to eq "555"
      expect(this.argument_timeout { |val| val * 3 }).to be_nil
    end
  end

  describe "#fetch" do

    it 'calls block if argument is present' do
      this.parse %w{-v --retries 5 example.com 80}

      expect(this.fetch :retries).to eq "5"
      expect(this.fetch :retries, "9000").to eq "5"
      expect(this.fetch(:retries) { "9000" }).to eq "5"
    end

    it 'skips block if argument is nil' do
      this.parse %w{-v --retries 5 example.com 80}

      expect { this.fetch :timeout }.to raise_error KeyError
      expect(this.fetch :timeout, "9000").to eq "9000"
      expect(this.fetch(:timeout) { "9000" }).to eq "9000"
    end
  end

  describe "#get" do

    it 'calls block if argument is present' do
      this.parse %w{-v --retries 5 example.com 80}

      expect(this.get :retries).to eq "5"
    end

    it 'skips block if argument is nil' do
      this.parse %w{-v --retries 5 example.com 80}

      expect(this.get :timeout).to be nil
    end
  end

  describe "#if_present" do

    it 'calls block if argument is present' do
      this.parse %w{-v --retries 5 example.com 80}

      expect(this.if_present(:retries) { |val| val * 3 }).to eq "555"
    end

    it 'skips block if argument is nil' do
      this.parse %w{-v --retries 5 example.com 80}

      expect(this.if_present(:timeout) { |val| val * 3 }).to be nil
    end
  end

  describe "#include?" do

    it 'returns true if option is present' do
      this.parse %w{-v --timeout 60 example.com 80}

      expect(this.include? :verbose).to be true
      expect(this.include? :timeout).to be true
    end

    it 'returns false if option is missing' do
      this.parse %w{-v --timeout 60 example.com 80}

      expect(this.include? :retries).to be_falsey
      expect(this.include? :secure).to be_falsey
    end
  end

  describe "#parse" do

    it 'parses options and arguments correctly' do
      this.parse %w{--secure -v --retries 5 active example.com 80}

      expect(this.options.keys).to match_array [:secure, :verbose, :retries]
      expect(this.arguments.keys).to match_array [:retries, :mode, :host, :port]
    end

    it 'raises an error for unknown options' do
      expect {
        this.parse %w{--foo example.com 80}
      }.to output_error "Found unknown option '--foo'"
    end

    it 'raises an error for missing required arguments' do
      expect {
        this.parse %w{-v example.com}
      }.to output_error "Expected 2 required arguments, but received only one"
    end

    it 'raises an error for missing arguments' do
      expect {
        this.parse %w{--retries -v example.com 80}
      }.to output_error "Expected argument for option '--retries', got none"
    end

    it 'raises a helpful error for unexpected arguments' do
      expect {
        this.parse %w{--secure gibberish -v example.com 80}
      }.to output_error "Unexpected arguments found before option '-v', please provide all options before arguments"
    end

    it 'raises a helpful error for options in argument section' do
      expect {
        this.parse %w{example.com 80 -v}
      }.to output_error "Unexpected arguments found before option '-v', please provide all options before arguments"
    end

    it 'raises a helpful error for ambigious missing arguments' do
      expect {
        this.parse %w{--timeout example.com 80}
      }.to output_error "Expected 2 required arguments, but received only one (considering --timeout takes an argument)"
    end

    it 'raises an error for too many arguments' do
      expect {
        this.parse %w{active example.com 80 gibberish}
      }.to output_error "Expected 2-3 arguments, but received too many"
    end
  end

  describe "parsing options" do

    let(:this) { OptionsByExample.new(%{Usage: $0 [--foo] [--bar ARG]}) }

    it 'parses empty command-line' do
      this.parse %w{}

      expect(this.options).to be_empty
      expect(this.arguments.keys).to be_empty
    end

    it 'parses both options' do
      this.parse %w{--foo --bar 5309}

      expect(this.options.keys).to match_array [:foo, :bar]
      expect(this.arguments.keys).to match_array [:bar]
      expect(this.arguments[:bar]).to eq '5309'
    end

    it 'parses one option' do
      this.parse %w{--foo}

      expect(this.options.keys).to match_array [:foo]
      expect(this.arguments).to be_empty
    end

    it 'raises an error for unexpected arguments' do
      expect {
        this.parse %w{lorem}
      }.to output_error "Expected 0 arguments, but received too many"
    end

    it 'raises an error for unexpected leading argument' do
      expect {
        this.parse %w{lorem --foo}
      }.to output_error "Unexpected arguments found before option '--foo', please provide all options before arguments"
    end

    it 'raises error for unexpected intermediate argument' do
      expect {
        this.parse %w{--foo lorem --bar}
      }.to output_error "Unexpected arguments found before option '--bar', please provide all options before arguments"
    end

    it 'raises error for unexpected trailing argument' do
      expect {
        this.parse %w{--foo lorem}
      }.to output_error "Expected 0 arguments, but received too many"
    end

    it 'raises an error for unknown options' do
      expect {
        this.parse %w{--foo --qux --bar}
      }.to output_error "Found unknown option '--qux'"
    end

    it 'detects help option' do
      expect {
        this.parse %w{--foo --help --bar}
      }.to output_usage_message_and_exit
    end
  end

  describe "parsing required arguments" do

    let(:this) { OptionsByExample.new(%{Usage: $0 source dest}) }

    it 'parses example arguments' do
      this.parse %w{80 443}

      expect(this.options.keys).to be_empty
      expect(this.arguments.keys).to match_array [:source, :dest]
    end

    it 'parses help option' do
      expect {
        this.parse %w{--foo --bar whatever --help}
      }.to output_usage_message_and_exit
    end

    it 'raises an error for emtpy ARGV' do
      expect {
        this.parse %w{}
      }.to output_error "Expected 2 required arguments, but received none"
    end

    it 'raises an error for missing required argumente' do
      expect {
        this.parse %w{80}
      }.to output_error "Expected 2 required arguments, but received only one"
    end

    it 'raises an error for too many arguments' do
      expect {
        this.parse %w{80 443 5309}
      }.to output_error "Expected 2 arguments, but received too many"
    end

    it 'raises an error for unknown options' do
      expect {
        this.parse %w{--verbose 80 443}
      }.to output_error "Found unknown option '--verbose'"
    end

    it 'raises an error for arguments before options' do
      expect {
        this.parse %w{80 443 --verbose}
      }.to output_error "Found unknown option '--verbose'"
    end
  end

  describe 'shorthand options' do

    it 'parses shorthand options' do
      this.parse %w{-s -v -t 60 example.com 443}

      expect(this.include_secure?).to be true
      expect(this.include_verbose?).to be true
      expect(this.include_retries?).to be_falsey
      expect(this.include_timeout?).to be true
      expect(this.argument_timeout).to eq '60'
    end

    it 'parses stacked shorthand options' do
      this.parse %w{-svt 60 example.com 443}

      expect(this.include_secure?).to be true
      expect(this.include_verbose?).to be true
      expect(this.include_retries?).to be_falsey
      expect(this.include_timeout?).to be true
      expect(this.argument_timeout).to eq '60'
    end

    it 'raises an error for unknown stacked shorthands' do
      expect {
        this.parse %w{-svat example.com 443}
      }.to output_error "Found unknown option -a inside '-svat'"
    end

    it 'raises a helpful error for matching longhand option' do
      expect {
        this.parse %w{-verbose example.com 80}
      }.to output_error "Found unknown option -e inside '-verbose', did you mean '--verbose'?"
    end
  end

  describe 'dash-number' do

    let(:this) {
      OptionsByExample.new(%{Usage: $0 [-n, --num NUM]})
    }

    it 'expands to dash-n option' do
      this.parse %w{-15}

      expect(this.include_num?).to be true
      expect(this.argument_num).to eq 15
    end
  end

  describe 'default values' do

    it 'uses default value' do
      this.parse %w{-v example.com 80}

      expect(this.include_retries?).to be_falsey
      expect(this.argument_retries).to eq '3'
    end

    it 'uses given value' do
      this.parse %w{--retries 5 -v example.com 80}

      expect(this.include_retries?).to be true
      expect(this.argument_retries).to eq '5'
    end

    it 'raises an error for missing argument' do
      expect {
        this.parse %w{--retries -v example.com 80}
      }.to output_error "Expected argument for option '--retries', got none"
    end
  end

  describe 'argument coercion' do

    let(:this) {
      OptionsByExample.new(%{Usage: $0 [--num NUM] [--date DATE] [--time TIME]})
    }

    it 'parses integer values' do
      this.parse %w{--num 60}

      expect(this.include_num?).to be true
      expect(this.argument_num).to eq 60
    end

    it 'parses dates' do
      this.parse %w{--date 1983-09-12}

      expect(this.include_date?).to be true
      expect(this.argument_date).to be_a Date
    end

    it 'parses timestamps' do
      this.parse %w{--time 14:41}

      expect(this.include_time?).to be true
      expect(this.argument_time).to be_a Time
    end

    it 'raises a helpful error for invalid arguments' do
      expect {
        this.parse %w{--num foo}
      }.to output_error "Invalid argument \"foo\" for option '--num', please provide an integer value"
    end
  end
end

