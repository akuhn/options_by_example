# frozen_string_literal: true


describe OptionsByExample do

  it 'has a version number' do
    expect(OptionsByExample::VERSION).not_to be nil
  end

  let(:usage_message) {
    %{
      Establishes network connection to designated host and port, enabling
      users to assess network connectivity and diagnose potential issues.

      Usage: connect [options] [mode] host port

      Options:
        -s, --secure        Establish a secure connection (SSL/TSL)
        -v, --verbose       Enable verbose output for detailed information
        -r, --retries NUM   Number of connection retries (default 3)
        -t, --timeout NUM   Connection timeout in seconds (default 10)

      Arguments:
        [mode]              Optional connection mode (active or passive)
        host                The target host to connect to (e.g., example.com)
        port                The target port to connect to (e.g., 80)
    }
  }

  let(:this) {
    OptionsByExample.new(usage_message)
  }


  it 'reads and parses options from DATA and ARGV' do
    ARGV.clear.concat %w{--secure example.com 80}
    DATA = StringIO.new usage_message
    Options = OptionsByExample.read(DATA).parse(ARGV)

    expect(Options.include_secure?).to be true
    expect(Options.argument_host).to eq 'example.com'
    expect(Options.argument_port).to eq '80'
  end

  describe "#initialize" do

    it 'parses optional argument names' do
      expect(this.instance_variable_get :@argument_names_optional).to eq %w{mode}
    end

    it 'parses required argument names' do
      expect(this.instance_variable_get :@argument_names_required).to eq %w{host port}
    end

    it 'parses option names' do
      expect((this.instance_variable_get :@option_names).keys).to match_array %w{
        -s --secure
        -v --verbose
        -r --retries
        -t --timeout
      }
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
        this.parse_without_exit %w{--gibberish example.com 80}
      }.to raise_error "Found unknown option '--gibberish'"
    end

    it 'raises an error for missing required arguments' do
      expect {
        this.parse_without_exit %w{--secure example.com}
      }.to raise_error "Missing required argument 'port'"
    end

    it 'raises an error for missing arguments' do
      expect {
        this.parse_without_exit %w{--retries --secure example.com 80}
      }.to raise_error "Expected argument for option '--retries', got none"
    end

    it 'raises an error for unexpected arguments' do
      expect {
        this.parse_without_exit %w{--secure gibberish active example.com 80}
      }.to raise_error "Expected 2-3 arguments, but received too many"
    end

    it 'raises an error for options in argument section' do
      expect {
        this.parse_without_exit %w{example.com --secure}
      }.to raise_error "Unexpected arguments found before option '--secure', please provide all options before arguments"
    end

    it 'raises an error for too many arguments' do
      expect {
        this.parse_without_exit %w{active example.com 80 gibberish}
      }.to raise_error "Expected 2-3 arguments, but received too many"
    end
  end

  describe "#method_missing" do

    before {
      this.parse_without_exit %w{--secure -v --retries 5 active example.com 80}
    }

    it 'returns argument value when called with argument_NAME method' do
      expect(this.argument_mode).to eq "active"
      expect(this.argument_host).to eq "example.com"
      expect(this.argument_port).to eq "80"
      expect(this.argument_retries).to eq "5"
      expect(this.argument_timeout).to be_nil
    end

    it 'returns option status when called with include_NAME? method' do
      expect(this.include_secure?).to be true
      expect(this.include_verbose?).to be true
      expect(this.include_retries?).to be true
      expect(this.include_timeout?).to be_falsey
    end
  end

  describe "parsing without arguments" do

    let(:this) {
      OptionsByExample
        .new(%{Usage: $0 [--foo] [--bar NUM]})
    }

    it 'parses empty ARGV' do
      this.parse_without_exit %w{}

      expect(this.options).to be_empty
      expect(this.arguments.keys).to be_empty
    end

    it 'parses options' do
      this.parse_without_exit %w{--foo --bar 2000}

      expect(this.options.keys).to match_array %w{foo bar}
      expect(this.arguments.keys).to match_array %w{bar}
      expect(this.arguments['bar']).to eq '2000'
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

    it 'raises an error for any arguments' do
      expect {
        this.parse_without_exit %w{lorem}
      }.to raise_error "Expected 0 arguments, but received too many"
    end

    it 'raises an error for unknown options' do
      expect {
        this.parse_without_exit %w{--qux}
      }.to raise_error "Found unknown option '--qux'"
    end
  end

  describe "parsing without options" do

    let(:this) {
      OptionsByExample
        .new(%{Usage: $0 source dest})
    }

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
      }.to raise_error "Missing required argument 'source'"
    end

    it 'raises an error for missing required argumente' do
      expect {
        this.parse_without_exit %w{80}
      }.to raise_error "Missing required argument 'dest'"
    end

    it 'raises an error for too many arguments' do
      expect {
        this.parse_without_exit %w{80 443 gibberish}
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
end

