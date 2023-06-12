# frozen_string_literal: true

class Binding
  def pry
    require 'pry'
    super
  end
end

module Helpers
  def exit_with_status(code)
    raise_error(SystemExit) { |err| expect(err.status).to eq code }
  end

  def output_usage_message_and_exit
    output(start_with 'Usage:').to_stdout.and exit_with_status(0)
  end

  def output_error(message)
    output("ERROR: #{message}\n").to_stdout.and exit_with_status(1)
  end
end

RSpec.configure do |config|

  config.include Helpers

  config.example_status_persistence_file_path = ".rspec_status"

  config.around :example do |example|
    begin
      example.run
    rescue SystemExit => err
      fail "Example called exit with status #{err.status}, program ended prematurely"
    end
  end
end

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start
end

require 'options_by_example'

