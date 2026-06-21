# frozen_string_literal: true
require 'options_by_example'


describe 'UsageSpecification' do

  def parse_spec(text)
    OptionsByExample::UsageSpecification.new text
  end

  it 'parses minimal specification' do
    usage = parse_spec 'Usage: command'

    expect(usage.option_names).to be_empty
    expect(usage.argument_names).to be_empty
  end

  it 'chokes on invalid usage syntax' do
    expect {
      parse_spec 'Usage: command arg ^^^ arg'
    }.to raise_error "Found invalid usage token '^^^'"
  end

  it 'chokes on preceding text' do
    expect {
      parse_spec 'preceding text Usage:'
    }.to raise_error RuntimeError
  end

  it 'expects command name or fails' do
    expect {
      parse_spec 'Usage:'
    }.to raise_error RuntimeError
  end

  it 'reports a helpful error when usage is split across lines' do
    expect {
      parse_spec "Usage:\n command [options] arg"
    }.to raise_error "Expected command name on same line as 'Usage:'"
  end

  it 'expects "Usage:" or fails' do
    expect {
      parse_spec 'whatever else'
    }.to raise_error "Expected usage string, got none"
  end

  it 'chokes when mixing optional and repeated arguments' do
    expect {
      parse_spec 'Usage: command arg files... [mode]'
    }.to raise_error "Cannot combine vararg and optional arguments"
  end

  it 'parses trailing vararg argument' do
    usage = parse_spec 'Usage: upload file type tags...'
    expect(usage.argument_names).to eq({
      file: :required,
      type: :required,
      tags: :vararg,
    })
  end

  it 'parses leading vararg argument' do
    usage = parse_spec 'Usage: filter logs... from until'
    expect(usage.argument_names).to eq({
      logs: :vararg,
      from: :required,
      until: :required,
    })
  end

  it 'parses vararg argument in the middle' do
    usage = parse_spec 'Usage: convert input files... format'
    expect(usage.argument_names).to eq({
      input: :required,
      files: :vararg,
      format: :required
    })
  end

  it 'treats space before ellipsis as vararg marker' do
    usage = parse_spec 'Usage: copy source ... dest'
    expect(usage.argument_names).to include source: :vararg
  end

  it 'parses multiple vararg arguments and errors' do
    expect {
      parse_spec 'Usage: merge sources... files...'
    }.to raise_error "Found more than one vararg arguments"
  end

  it 'treats lone dotted argument as vararg' do
    usage = parse_spec 'Usage: print items...'
    expect(usage.argument_names).to eq items: :vararg
  end

  it 'treats bracketed dotted argument as optional vararg' do
    usage = parse_spec 'Usage: print [items...]'
    expect(usage.argument_names).to eq items: :optional_vararg
  end

  it 'treats bracketed option argument as optional' do
    usage = parse_spec 'Usage: backup [--quiet] [--compress [level]] source'

    expect(usage.option_names['--quiet']).to eq [:quiet, nil, nil, nil]
    expect(usage.option_names['--compress']).to eq [:compress, :optional, 'level', nil]
    expect(usage.argument_names).to eq source: :required
  end

  it 'parses shorthand-only option with optional argument' do
    usage = parse_spec 'Usage: backup [-c [level]] src'

    expect(usage.option_names['-c']).to eq [:c, :optional, 'level', nil]
    expect(usage.argument_names).to eq src: :required
  end

  it 'parses shorthand and longhand option with optional argument' do
    usage = parse_spec 'Usage: backup [-c, --compress [level]] src'

    expect(usage.option_names['-c']).to eq [:compress, :optional, 'level', nil]
    expect(usage.option_names['--compress']).to eq [:compress, :optional, 'level', nil]
  end

  it 'parses inline defaults for optional option arguments' do
    usage = parse_spec 'Usage: backup [--compress NUM? (default 7)] source'

    expect(usage.option_names['--compress']).to eq [:compress, :optional, 'NUM', '7']
  end

  it 'treats text after one space as option argument' do
    usage = parse_spec 'Usage: command [--option foo]'

    expect(usage.option_names['--option']).to eq [:option, :required, 'foo', nil]
  end

  it 'treats text after tab as description' do
    usage = parse_spec "Usage: command [--option\tfoo]"

    expect(usage.option_names['--option']).to eq [:option, nil, nil, nil]
  end

  it 'treats text after two spaces as description' do
    usage = parse_spec 'Usage: command [--option  foo]'

    expect(usage.option_names['--option']).to eq [:option, nil, nil, nil]
  end

  it 'parses optional vararg argument' do
    usage = parse_spec 'Usage: connect host port [mode] [files...]'

    expect(usage.argument_names).to eq({
      host: :required,
      port: :required,
      mode: :optional,
      files: :optional_vararg,
    })
  end

  it 'chokes when optional vararg argument is not trailing' do
    expect {
      parse_spec 'Usage: print [items...] [mode]'
    }.to raise_error "Found invalid usage token '[mode]'" # FIXME better message
  end

  it 'chokes when mixing vararg and optional vararg arguments' do
    expect {
      parse_spec 'Usage: print items... [more...]'
    }.to raise_error "Cannot combine vararg and optional arguments"
  end
end
