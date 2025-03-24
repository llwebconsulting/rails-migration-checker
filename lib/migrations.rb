require_relative "migrations/version"
require_relative "migrations/cli"
require_relative "migrations/validator"

module Migrations
  class Error < StandardError; end
  
  def self.validate(migrations_path)
    validator = Validator.new(migrations_path)
    validator.validate
  end
end 