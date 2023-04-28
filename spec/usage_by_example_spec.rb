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
    OptionsByExample.new(usage_message).use(exit_on_error: false)
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
      expect(this.argument_names_optional).to eq %w{mode}
    end

    it 'parses required argument names' do
      expect(this.argument_names_required).to eq %w{host port}
    end

    it 'parses option names' do
      expect(this.option_names.keys).to match_array %w{
        -s --secure
        -v --verbose
        -r --retries
        -t --timeout
      }
    end
  end

  describe "#parse" do

    it 'parses options and arguments correctly' do
      this.parse %w{--secure -v --retries 5 active example.com 80}

      expect(this.options.keys).to match_array %w{secure verbose retries}
      expect(this.arguments.keys).to match_array %w{retries mode host port}
    end

    it 'raises an error for unknown options' do
      expect {
        this.parse %w{--gibberish example.com 80}
      }.to raise_error "Found unknown option '--gibberish'"
    end

    it 'raises an error for missing required arguments' do
      expect {
        this.parse %w{--secure example.com}
      }.to raise_error "Missing required argument 'port'"
    end

    it 'raises an error for missing arguments' do
      expect {
        this.parse %w{--retries --secure example.com 80}
      }.to raise_error "Expected argument for option '--retries', got none"
    end

    it 'raises an error for unexpected arguments' do
      expect {
        this.parse %w{--secure gibberish active example.com 80}
      }.to raise_error "Expected 2-3 arguments, but received too many"
    end

    it 'raises an error for options in argument section' do
      expect {
        this.parse %w{example.com --secure}
      }.to raise_error "Expected arguments, but found option '--secure'"
    end

    it 'raises an error for too many arguments' do
      expect {
        this.parse %w{active example.com 80 gibberish}
      }.to raise_error "Expected 2-3 arguments, but received too many"
    end
  end

  describe "#method_missing" do

    before {
      this.parse %w{--secure -v --retries 5 active example.com 80}
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

  describe "usage message without arguments" do

    let(:usage_message) {
      %{
        Prints out a friendly greeting message to the current user.

        Usage: greet [options]

        Options:
            -f, --formal        Use a formal greeting instead of an informal one
            -v, --verbose       Enable verbose output for detailed information
      }
    }

    it 'parses empty ARGV' do
      this.parse %w{}

      expect(this.include_formal?).to be_falsey
      expect(this.include_verbose?).to be_falsey
    end

    it 'raises an error for any arguments' do
      expect {
        this.parse %w{gibberish}
      }.to raise_error "Expected 0 arguments, but received too many"
    end

    it 'raises an error for unknown options' do
      expect {
        this.parse %w{--gibberish}
      }.to raise_error "Found unknown option '--gibberish'"
    end
  end

  describe "usage message without options" do

    let(:usage_message) {
      %{
        This script redirects all traffic from one port to another.

        Usage: redirect SOURCE DEST
      }
    }

    it 'parses example arguments' do
      this.parse %w{80 443}

      expect(this.argument_source).to eq "80"
      expect(this.argument_dest).to eq "443"
    end

    # it 'parses the default help option' do
    #   expect {
    #     this.use(exit_on_error: true).parse %w{--help}
    #   }.to raise_error SystemExit
    # end

    it 'raises an error for emtpy ARGV' do
      expect {
        this.parse %w{}
      }.to raise_error "Missing required argument 'source'"
    end

    it 'raises an error for too many arguments' do
      expect {
        this.parse %w{in out gibberish}
      }.to raise_error "Expected 2 arguments, but received too many"
    end

    it 'raises an error for unknown options' do
      expect {
        this.parse %w{--verbose}
      }.to raise_error "Found unknown option '--verbose'"
    end
  end
end

