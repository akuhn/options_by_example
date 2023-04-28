# frozen_string_literal: true


describe UsageByExample do

  it 'has a version number' do
    expect(UsageByExample::VERSION).not_to be nil
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

  it 'reads and parses options from DATA and ARGV' do
    ARGV.concat %w{--secure example.com 80}
    DATA = StringIO.new usage_message
    Options = UsageByExample.read(DATA).parse(ARGV)

    p Options.options
    p Options.arguments

    expect(Options.include_secure?).to be true
    expect(Options.argument_host).to eq 'example.com'
    expect(Options.argument_port).to eq '80'
  end

  let(:this) { UsageByExample.new(usage_message) }

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
        -h --help
      }
    end
  end

  describe "#parse" do

    it 'parses options and arguments correctly' do
      this.parse %w{--secure -v --retries 5 active example.com 80}

      expect(this.options.keys).to match_array %w{secure verbose retries}
      expect(this.arguments.keys).to match_array %w{retries mode host port}
    end

    it "raises an error for unknown options" do
      argv = %w{--gibberish example.com 80}

      expect {
        this.parse argv, exit_on_error: false
      }.to raise_error "Got unknown option --gibberish"
    end

    it "raises an error for missing required arguments" do
      argv = %w{--secure example.com}

      expect {
        this.parse argv, exit_on_error: false
      }.to raise_error "Expected required argument PORT, got none"
    end

    it "raises an error for unexpected arguments" do
      argv = %w{--secure gibberish active example.com 80}

      expect {
        this.parse argv, exit_on_error: false
      }.to raise_error "Got unexpected argument for option --secure"
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

    it "returns option status when called with include_NAME? method" do
      expect(this.include_secure?).to be true
      expect(this.include_verbose?).to be true
      expect(this.include_retries?).to be true
      expect(this.include_timeout?).to be_falsey
    end
  end
end


__END__
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
