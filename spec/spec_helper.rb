# frozen_string_literal: true

require 'options_by_example'

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"

  config.around :example do |example|
    begin
      example.run
    rescue SystemExit => err
      fail "Example called exit with status #{err.status}, program ended prematurely"
    end
  end
end
