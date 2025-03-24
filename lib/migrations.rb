# frozen_string_literal: true

require_relative "migrations/version"
require_relative "migrations/cli"
require_relative "migrations/validator"
require_relative "migrations/tasks"
require_relative "migrations/railtie" if defined?(Rails)

# Main module for the Migrations gem
module Migrations
  class Error < StandardError; end
  class ValidationError < Error; end
  class CircularDependencyError < Error; end

  def self.validate(migrations_path)
    Validator.new(migrations_path).validate
  end
end
