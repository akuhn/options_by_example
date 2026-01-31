# frozen_string_literal: true
require 'options_by_example'


describe 'UsageSpecification' do

  it 'parses minimal specification' do
    usage = OptionsByExample::UsageSpecification.new 'Usage: command'

    expect(usage.option_names).to be_empty
    expect(usage.argument_names).to be_empty
  end
end

