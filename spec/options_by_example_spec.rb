# frozen_string_literal: true


describe OptionsByExample do

  it 'has a version number' do
    expect(OptionsByExample::VERSION).not_to be nil
  end

  it 'reads and parses options from DATA and ARGV' do
    DATA = StringIO.new usage_message
    ARGV.clear.concat %w{--secure example.com 443}
    Options = OptionsByExample.read(DATA).parse(ARGV)

    expect(Options.include_secure?).to be true
    expect(Options.argument_host).to eq 'example.com'
    expect(Options.argument_port).to eq '443'
  end

  it 'parses options and extends ARGV with symbols' do
    ARGV.clear.concat %w{--secure example.com 443}
    OptionsByExample.new(usage_message).parse_and_extend(ARGV)

    expect(ARGV.include? :secure).to be true
    expect(ARGV[:host]).to eq 'example.com'
    expect(ARGV[:port]).to eq '443'
  end

  it 'supports one-line usage messages' do
    usage = 'Usage: $0 [-v,--verbose] [-i,--interactive]'
    this = OptionsByExample.new(usage).parse(%w{-v})

    expect(this.include_verbose?).to be true
    expect(this.include_interactive?).to be false
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

  let(:subject) { OptionsByExample.new(usage_message) }

  let(:parser) { OptionsByExample::Parser.new(subject) }

  describe "#initialize" do

    it 'parses optional argument names' do
      expect(subject.argument_names_optional).to eq [:mode]
    end

    it 'parses required argument names' do
      expect(subject.argument_names_required).to eq [:host, :port]
    end

    it 'parses all options' do
      option_names = subject.option_names
      expect(option_names['-v']).to eq [:verbose, nil]
      expect(option_names['--verbose']).to eq [:verbose, nil]
      expect(option_names['--retries']).to eq [:retries, "ARG"]
      expect(option_names.size).to be 8
    end

    it 'parses default values' do
      default_values = subject.default_values
      expect(default_values[:retries]).to eq "3"
      expect(default_values.size).to be 1
    end
  end

  describe 'custom accessor methods' do

    let(:this) { subject.parse %w{example.com 443} }

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
      this = OptionsByExample.new(usage).parse(%w{})

      expect(this).to respond_to :include_find_matches?
      expect(this).to respond_to :include_enable_feature?
      expect(this).to respond_to :argument_enable_feature
    end
  end

  describe "#include_NAME?" do

    it 'returns option status' do
      this = parser.parse %w{-v --timeout 60 example.com 80}

      expect(this.include_verbose?).to be true
      expect(this.include_retries?).to be_falsey
      expect(this.include_secure?).to be_falsey
      expect(this.include_timeout?).to be true
    end
  end

  describe "#argument_NAME" do

    it 'returns positional argument values' do
      this = parser.parse %w{-v --retries 5 example.com 80}

      expect(this.argument_mode).to be_nil
      expect(this.argument_host).to eq "example.com"
      expect(this.argument_port).to eq "80"
    end

    it 'returns optional argument values' do
      this = parser.parse %w{-v --retries 5 example.com 80}

      expect(this.argument_retries).to eq "5"
      expect(this.argument_timeout).to be_nil
    end

    it 'passes arguments through block' do
      this = parser.parse %w{-v --retries 5 example.com 80}

      expect(this.argument_retries { |val| val * 3 }).to eq "555"
      expect(this.argument_timeout { |val| val * 3 }).to be_nil
    end
  end

  describe "#parse" do

    it 'parses options and arguments correctly' do
      this = parser.parse %w{--secure -v --retries 5 active example.com 80}

      expect(this.options.keys).to match_array [:secure, :verbose, :retries]
      expect(this.arguments.keys).to match_array [:retries, :mode, :host, :port]
    end

    it 'raises an error for unknown options' do
      expect {
        parser.parse %w{--foo example.com 80}
      }.to raise_error "Found unknown option '--foo'"
    end

    it 'raises an error for missing required arguments' do
      expect {
        parser.parse %w{-v example.com}
      }.to raise_error "Expected 2 required arguments, but received only one"
    end

    it 'raises an error for missing arguments' do
      expect {
        parser.parse %w{--retries -v example.com 80}
      }.to raise_error "Expected argument for option '--retries', got none"
    end

    it 'raises a helpful error for unexpected arguments' do
      expect {
        parser.parse %w{--secure gibberish -v example.com 80}
      }.to raise_error "Unexpected arguments found before option '-v', please provide all options before arguments"
    end

    it 'raises a helpful error for options in argument section' do
      expect {
        parser.parse %w{example.com 80 -v}
      }.to raise_error "Unexpected arguments found before option '-v', please provide all options before arguments"
    end

    it 'raises a helpful error for ambigious missing arguments' do
      expect {
        parser.parse %w{--timeout example.com 80}
      }.to raise_error "Expected 2 required arguments, but received only one (considering --timeout takes an argument)"
    end

    it 'raises an error for too many arguments' do
      expect {
        parser.parse %w{active example.com 80 gibberish}
      }.to raise_error "Expected 2-3 arguments, but received too many"
    end
  end

  describe "parsing options only" do

    let(:subject) { OptionsByExample.new(%{Usage: $0 [--foo] [--bar ARG]}) }

    it 'parses empty command-line' do
      this = parser.parse %w{}

      expect(this.options).to be_empty
      expect(this.arguments.keys).to be_empty
    end

    it 'parses both options' do
      this = parser.parse %w{--foo --bar 5309}

      expect(this.options.keys).to match_array [:foo, :bar]
      expect(this.arguments.keys).to match_array [:bar]
      expect(this.arguments[:bar]).to eq '5309'
    end

    it 'parses one option' do
      this = parser.parse %w{--foo}

      expect(this.options.keys).to match_array [:foo]
      expect(this.arguments).to be_empty
    end

    it 'raises an error for unexpected arguments' do
      expect {
        parser.parse %w{lorem}
      }.to raise_error "Expected 0 arguments, but received too many"
    end

    it 'raises an error for unexpected leading argument' do
      expect {
        parser.parse %w{lorem --foo}
      }.to raise_error "Unexpected arguments found before option '--foo', please provide all options before arguments"
    end

    it 'raises error for unexpected intermediate argument' do
      expect {
        parser.parse %w{--foo lorem --bar}
      }.to raise_error "Unexpected arguments found before option '--bar', please provide all options before arguments"
    end

    it 'raises error for unexpected trailing argument' do
      expect {
        parser.parse %w{--foo lorem}
      }.to raise_error "Expected 0 arguments, but received too many"
    end

    it 'raises an error for unknown options' do
      expect {
        parser.parse %w{--foo --qux --bar}
      }.to raise_error "Found unknown option '--qux'"
    end

    it 'detects help option' do
      expect {
        parser.parse %w{--foo --help --bar}
      }.to raise_error OptionsByExample::PrintUsageMessage
    end
  end

  describe "parsing required arguments only" do

    let(:subject) { OptionsByExample.new(%{Usage: $0 source dest}) }

    it 'parses example arguments' do
      this = parser.parse %w{80 443}

      expect(this.options.keys).to be_empty
      expect(this.arguments.keys).to match_array [:source, :dest]
    end

    it 'parses help option' do
      expect {
        parser.parse %w{--foo --bar whatever --help}
      }.to raise_error OptionsByExample::PrintUsageMessage
    end

    it 'raises an error for emtpy ARGV' do
      expect {
        parser.parse %w{}
      }.to raise_error "Expected 2 required arguments, but received none"
    end

    it 'raises an error for missing required argumente' do
      expect {
        parser.parse %w{80}
      }.to raise_error "Expected 2 required arguments, but received only one"
    end

    it 'raises an error for too many arguments' do
      expect {
        parser.parse %w{80 443 5309}
      }.to raise_error "Expected 2 arguments, but received too many"
    end

    it 'raises an error for unknown options' do
      expect {
        parser.parse %w{--verbose 80 443}
      }.to raise_error "Found unknown option '--verbose'"
    end

    it 'raises an error for arguments before options' do
      expect {
        parser.parse %w{80 443 --verbose}
      }.to raise_error "Found unknown option '--verbose'"
    end
  end

  describe 'shorthand options' do

    it 'parses shorthand options' do
      this = parser.parse %w{-s -v -t 60 example.com 443}

      expect(this.include_secure?).to be true
      expect(this.include_verbose?).to be true
      expect(this.include_retries?).to be_falsey
      expect(this.include_timeout?).to be true
      expect(this.argument_timeout).to eq '60'
    end

    it 'parses stacked shorthand options' do
      this = parser.parse %w{-svt 60 example.com 443}

      expect(this.include_secure?).to be true
      expect(this.include_verbose?).to be true
      expect(this.include_retries?).to be_falsey
      expect(this.include_timeout?).to be true
      expect(this.argument_timeout).to eq '60'
    end

    it 'raises an error for unknown stacked shorthands' do
      expect {
        parser.parse %w{-svat example.com 443}
      }.to raise_error "Found unknown option -a inside '-svat'"
    end

    it 'raises a helpful error for matching longhand option' do
      expect {
        parser.parse %w{-verbose example.com 80}
      }.to raise_error "Found unknown option -e inside '-verbose', did you mean '--verbose'?"
    end
  end

  describe 'default values' do

    it 'uses default value' do
      this = parser.parse %w{-v example.com 80}

      expect(this.include_retries?).to be_falsey
      expect(this.argument_retries).to eq '3'
    end

    it 'uses given value' do
      this = parser.parse %w{--retries 5 -v example.com 80}

      expect(this.include_retries?).to be true
      expect(this.argument_retries).to eq '5'
    end

    it 'raises an error for missing argument' do
      expect {
        parser.parse %w{--retries -v example.com 80}
      }.to raise_error "Expected argument for option '--retries', got none"
    end
  end

  describe 'argument coercion' do

    let(:subject) {
      OptionsByExample.new(%{Usage: $0 [--num NUM] [--date DATE] [--time TIME]})
    }

    it 'parses integer values' do
      this = parser.parse %w{--num 60}

      expect(this.include_num?).to be true
      expect(this.argument_num).to eq 60
    end

    it 'parses dates' do
      this = parser.parse %w{--date 1983-09-12}

      expect(this.include_date?).to be true
      expect(this.argument_date).to be_a Date
    end

    it 'parses timestamps' do
      this = parser.parse %w{--time 14:41}

      expect(this.include_time?).to be true
      expect(this.argument_time).to be_a Time
    end

    it 'raises a helpful error for invalid arguments' do
      expect {
        parser.parse %w{--num foo}
      }.to raise_error "Invalid argument \"foo\" for option '--num', please provide an integer value"
    end
  end

  describe '#parse_and_extend' do

    let(:argv) { %w{--secure example.com 443} }

    before(:each) do
      OptionsByExample.new(usage_message).parse_and_extend(argv)
    end

    it 'returns default value for arguments' do
      expect(argv[:retries]).to eq "3"
    end

    it 'returns nil for missing arguments' do
      expect(argv[:timeout]).to be nil
    end

    it 'returns nil for unknown arguments' do
      expect(argv[:unknwon_argument_name]).to be nil
    end

    it 'returns true for present options' do
      expect(argv.include? :secure).to be true
    end

    it 'returns false for missing options' do
      expect(argv.include? :verbose).to be_falsey
    end

    it 'returns false for unknown options' do
      expect(argv.include? :unknwon_option_name).to be_falsey
    end

    it 'does not actually add array elements' do
      expect(argv.length).to eq 3
      expect(argv).to eq %w{--secure example.com 443}
    end

    it 'supports dash in option names' do
      usage = 'Usage: $0 [--find-matches] [--enable-feature NAME]'
      argv = %w{--find-matches --enable-feature EASTER_EGG}
      OptionsByExample.new(usage).parse_and_extend(argv)

      expect(argv.include? :find_matches).to be true
      expect(argv.include? :enable_feature).to be true
      expect(argv[:enable_feature]).to eq 'EASTER_EGG'
    end

    it 'does not break default functionality' do
      expect(argv.include?('--secure')).to be true
      expect(argv.include?(9000)).to be false

      expect(argv[0]).to eq '--secure'
      expect(argv[1, 2]).to eq %w{example.com 443}
      expect { argv['foo'] }.to raise_error TypeError
    end
  end
end

