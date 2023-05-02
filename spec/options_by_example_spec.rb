# frozen_string_literal: true


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

    it 'parses optional argument names' do
      expect(this.instance_variable_get :@argument_names_optional).to eq %w{mode}
    end

    it 'parses required argument names' do
      expect(this.instance_variable_get :@argument_names_required).to eq %w{host port}
    end

    it 'parses option names' do
      expect(this.instance_variable_get :@option_names).to include *%w{
         -r -s -t -v --retries --secure --timeout --verbose
      }
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
  end

  describe "#include_NAME?" do

    it 'returns option status' do
      this.parse_without_exit %w{-v --timeout 60 example.com 80}

      expect(this.include_verbose?).to be true
      expect(this.include_retries?).to be_falsey
      expect(this.include_secure?).to be_falsey
      expect(this.include_timeout?).to be true
    end
  end

  describe "#argument_NAME" do

    it 'returns positional argument values' do
      this.parse_without_exit %w{-v --retries 5 example.com 80}

      expect(this.argument_mode).to be_nil
      expect(this.argument_host).to eq "example.com"
      expect(this.argument_port).to eq "80"
    end

    it 'returns optional argument values' do
      this.parse_without_exit %w{-v --retries 5 example.com 80}

      expect(this.argument_retries).to eq "5"
      expect(this.argument_timeout).to be_nil
    end

    it 'passes arguments through block' do
      this.parse_without_exit %w{-v --retries 5 example.com 80}

      expect(this.argument_retries { |val| val * 3 }).to eq "555"
      expect(this.argument_timeout { |val| val * 3 }).to be_nil
    end
  end

  describe "#parse" do

    it 'parses options and arguments correctly' do
      this.parse_without_exit %w{--secure -v --retries 5 active example.com 80}

      expect(this.options.keys).to match_array %w{secure verbose retries}
      expect(this.arguments.keys).to match_array %w{retries mode host port}
    end

    it 'raises an error for unknown options' do
      expect {
        this.parse_without_exit %w{--foo example.com 80}
      }.to raise_error "Found unknown option '--foo'"
    end

    it 'raises an error for missing required arguments' do
      expect {
        this.parse_without_exit %w{-v example.com}
      }.to raise_error "Expected 2 required arguments, but received only one"
    end

    it 'raises an error for missing arguments' do
      expect {
        this.parse_without_exit %w{--retries -v example.com 80}
      }.to raise_error "Expected argument for option '--retries', got none"
    end

    it 'raises a helpful error for unexpected arguments' do
      expect {
        this.parse_without_exit %w{--secure gibberish -v example.com 80}
      }.to raise_error "Unexpected arguments found before option '-v', please provide all options before arguments"
    end

    it 'raises a helpful error for options in argument section' do
      expect {
        this.parse_without_exit %w{example.com 80 -v}
      }.to raise_error "Unexpected arguments found before option '-v', please provide all options before arguments"
    end

    it 'raises a helpful error for ambigious missing arguments' do
      expect {
        this.parse_without_exit %w{--timeout example.com 80}
      }.to raise_error "Expected 2 required arguments, but received only one (considering --timeout takes an argument)"
    end

    it 'raises an error for too many arguments' do
      expect {
        this.parse_without_exit %w{active example.com 80 gibberish}
      }.to raise_error "Expected 2-3 arguments, but received too many"
    end
  end

  describe "parsing options only" do

    let(:this) { OptionsByExample.new(%{Usage: $0 [--foo] [--bar ARG]}) }

    it 'parses empty command-line' do
      this.parse_without_exit %w{}

      expect(this.options).to be_empty
      expect(this.arguments.keys).to be_empty
    end

    it 'parses both options' do
      this.parse_without_exit %w{--foo --bar 5309}

      expect(this.options.keys).to match_array %w{foo bar}
      expect(this.arguments.keys).to match_array %w{bar}
      expect(this.arguments['bar']).to eq '5309'
    end

    it 'parses one option' do
      this.parse_without_exit %w{--foo}

      expect(this.options.keys).to match_array %w{foo}
      expect(this.arguments).to be_empty
    end

    it 'raises an error for unexpected arguments' do
      expect {
        this.parse_without_exit %w{lorem}
      }.to raise_error "Expected 0 arguments, but received too many"
    end

    it 'raises an error for unexpected leading argument' do
      expect {
        this.parse_without_exit %w{lorem --foo}
      }.to raise_error "Unexpected arguments found before option '--foo', please provide all options before arguments"
    end

    it 'raises error for unexpected intermediate argument' do
      expect {
        this.parse_without_exit %w{--foo lorem --bar}
      }.to raise_error "Unexpected arguments found before option '--bar', please provide all options before arguments"
    end

    it 'raises error for unexpected trailing argument' do
      expect {
        this.parse_without_exit %w{--foo lorem}
      }.to raise_error "Expected 0 arguments, but received too many"
    end

    it 'raises an error for unknown options' do
      expect {
        this.parse_without_exit %w{--foo --qux --bar}
      }.to raise_error "Found unknown option '--qux'"
    end

    it 'detects help option' do
      expect {
        this.parse_without_exit %w{--foo --help --bar}
      }.to raise_error OptionsByExample::PrintUsageMessage
    end
  end

  describe "parsing required arguments only" do

    let(:this) { OptionsByExample.new(%{Usage: $0 source dest}) }

    it 'parses example arguments' do
      this.parse_without_exit %w{80 443}

      expect(this.options.keys).to be_empty
      expect(this.arguments.keys).to match_array %w{source dest}
    end

    it 'parses help option' do
      expect {
        this.parse_without_exit %w{--foo --bar whatever --help}
      }.to raise_error OptionsByExample::PrintUsageMessage
    end

    it 'raises an error for emtpy ARGV' do
      expect {
        this.parse_without_exit %w{}
      }.to raise_error "Expected 2 required arguments, but received none"
    end

    it 'raises an error for missing required argumente' do
      expect {
        this.parse_without_exit %w{80}
      }.to raise_error "Expected 2 required arguments, but received only one"
    end

    it 'raises an error for too many arguments' do
      expect {
        this.parse_without_exit %w{80 443 5309}
      }.to raise_error "Expected 2 arguments, but received too many"
    end

    it 'raises an error for unknown options' do
      expect {
        this.parse_without_exit %w{--verbose 80 443}
      }.to raise_error "Found unknown option '--verbose'"
    end

    it 'raises an error for arguments before options' do
      expect {
        this.parse_without_exit %w{80 443 --verbose}
      }.to raise_error "Found unknown option '--verbose'"
    end
  end

  describe 'shorthand options' do

    it 'parses shorthand options' do
      this.parse_without_exit %w{-s -v -t 60 example.com 443}

      expect(this.include_secure?).to be true
      expect(this.include_verbose?).to be true
      expect(this.include_retries?).to be_falsey
      expect(this.include_timeout?).to be true
      expect(this.argument_timeout).to eq '60'
    end

    it 'parses stacked shorthand options' do
      this.parse_without_exit %w{-svt 60 example.com 443}

      expect(this.include_secure?).to be true
      expect(this.include_verbose?).to be true
      expect(this.include_retries?).to be_falsey
      expect(this.include_timeout?).to be true
      expect(this.argument_timeout).to eq '60'
    end

    it 'raises an error for unknown stacked shorthands' do
      expect {
        this.parse_without_exit %w{-svat example.com 443}
      }.to raise_error "Found unknown option -a inside '-svat'"
    end

    it 'raises a helpful error for matching longhand option' do
      expect {
        this.parse_without_exit %w{-verbose example.com 80}
      }.to raise_error "Found unknown option -e inside '-verbose', did you mean '--verbose'?"
    end
  end

  describe 'default values' do

    it 'uses default value' do
      this.parse_without_exit %w{-v example.com 80}

      expect(this.include_retries?).to be_falsey
      expect(this.argument_retries).to eq '3'
    end

    it 'uses given value' do
      this.parse_without_exit %w{--retries 5 -v example.com 80}

      expect(this.include_retries?).to be true
      expect(this.argument_retries).to eq '5'
    end

    it 'raises an error for missing argument' do
      expect {
        this.parse_without_exit %w{--retries -v example.com 80}
      }.to raise_error "Expected argument for option '--retries', got none"
    end
  end

  describe 'argument coercion' do

    let(:this) {
      OptionsByExample.new(%{Usage: $0 [--num NUM] [--date DATE] [--time TIME]})
    }

    it 'parses integer values' do
      this.parse_without_exit %w{--num 60}

      expect(this.include_num?).to be true
      expect(this.argument_num).to eq 60
    end

    it 'parses dates' do
      this.parse_without_exit %w{--date 1983-09-12}

      expect(this.include_date?).to be true
      expect(this.argument_date).to be_a Date
    end

    it 'parses timestamps' do
      this.parse_without_exit %w{--time 14:41}

      expect(this.include_time?).to be true
      expect(this.argument_time).to be_a Time
    end

    it 'raises a helpful error for invalid arguments' do
      expect {
        this.parse_without_exit %w{--num foo}
      }.to raise_error "Invalid argument \"foo\" for option '--num', please provide an integer value"
    end
  end
end

