# frozen_string_literal: true

require_relative "lib/usage_by_example/version"


# Verify that the gem is being built with matching git tag and gem version,
# and check for uncommitted changes in the repository. If the script is not
# run during a gem build, appends "beta" to the gem version.

if caller.grep(/rubygems.commands.build_command.rb/).any?
  gem_version = UsageByExample::VERSION
  tag_version = `git describe --tags`.strip
  unless tag_version == "v#{gem_version}"
    raise "Current git tag #{tag_version} does not match gem version #{gem_version}"
  end
  unless `git status --porcelain`.strip.empty?
    raise "There are uncommitted changes in the repository, please commit them before proceeding."
  end
else
  gem_version = "#{UsageByExample::VERSION}.beta"
end


Gem::Specification.new do |spec|
  spec.name = "usage_by_example"
  spec.version = gem_version
  spec.authors = ["Adrian Kuhn"]
  spec.email = ["akuhn@iam.unibe.ch"]
  spec.license = "MIT"

  spec.summary = "No-code options parser that extracts arguments directly from usage text."
  spec.homepage = "https://github.com/akuhn/usage_by_example"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/akuhn/usage_by_example"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.require_paths = ["lib"]

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
