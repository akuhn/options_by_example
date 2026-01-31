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

  it 'parses trailing dotted argument' do
    usage = parse_spec 'Usage: upload file type tags...'
    expect(usage.argument_names).to eq({
      file: :required,
      type: :required,
      tags: :vararg,
    })
  end

  it 'parses leading dotted argument' do
    usage = parse_spec 'Usage: filter logs... from until'
    expect(usage.argument_names).to eq({
      logs: :vararg,
      from: :required,
      until: :required,
    })
  end

  it 'parses dotted argument in the middle' do
    usage = parse_spec 'Usage: convert input files... format'
    expect(usage.argument_names).to eq({
      input: :required,
      files: :vararg,
      format: :required
    })
  end

  it 'parses dotted arguments with whitespace' do
    usage = parse_spec 'Usage: copy source ... dest'
    expect(usage.argument_names).to include source: :vararg
  end

  it 'parses multiple dotted arguments and errors' do
    expect {
      parse_spec 'Usage: merge sources... files...'
    }.to raise_error "Found more than one dotted arguments"
  end

  it 'parses only dotted argument' do
    usage = parse_spec 'Usage: print items...'
    expect(usage.argument_names).to eq items: :vararg
  end
end

