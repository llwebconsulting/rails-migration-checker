# frozen_string_literal: true

require_relative "lib/migrations/version"

Gem::Specification.new do |spec|
  spec.name = "migrations"
  spec.version = Migrations::VERSION
  spec.authors = ["Carl Smith"]
  spec.email = ["carl@llweb.biz"]

  spec.summary = "A collection of tools to help manage Rails migrations"
  spec.description = "A collection of tools to help manage Rails migrations"
  spec.homepage = "https://github.com/cmer/migrations"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/cmer/migrations"
  spec.metadata["changelog_uri"] = "https://github.com/cmer/migrations/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?("bin/", "test/", "spec/", "features/", ".git", ".circleci", "appveyor", "Gemfile")
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 6.1.0", "< 8.0.0"
  spec.metadata["rubygems_mfa_required"] = "true"
end
