require_relative "lib/migrations/version"

Gem::Specification.new do |spec|
  spec.name          = "migrations"
  spec.version       = Migrations::VERSION
  spec.authors       = ["Carl"]
  spec.email         = ["carl@example.com"]

  spec.summary       = "A gem to validate Rails migrations in CI"
  spec.description   = "A tool to catch common Rails migration issues early in the CI pipeline"
  spec.homepage      = "https://github.com/llwebconsulting/rails-migration-checker"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.glob("{bin,lib}/**/*") + %w[README.md LICENSE.txt CHANGELOG.md]
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 6.0.0"
  spec.add_dependency "thor", ">= 1.0.0"
  spec.add_dependency "rake", ">= 13.0"
  spec.add_dependency "rails", ">= 6.0.0"

  spec.add_development_dependency "minitest", ">= 5.0"
  spec.add_development_dependency "rubocop", ">= 1.0"
  spec.add_development_dependency "rubocop-minitest", "~> 0.34.1"
  spec.add_development_dependency "rubocop-rake", "~> 0.6.0"
  spec.add_development_dependency "yard", "~> 0.9.34"
  spec.add_development_dependency "bundler-audit", "~> 0.9.1"
end 