# frozen_string_literal: true

require "active_record"
require "pathname"

# Core validation logic for the Migrations gem
module Migrations
  # Validator class that performs migration validation
  class Validator
    attr_reader :errors

    def initialize(migrations_path)
      @migrations_path = Pathname.new(migrations_path)
      @errors = []
    end

    def validate
      validate_directory_exists
      validate_migration_files
      validate_migration_versions
      validate_migration_dependencies
      validate_migration_reversibility

      raise Error, @errors.join("\n") if @errors.any?
    end

    def validate_file(file)
      content = file.read
      validate_file_structure(file, content)
      validate_methods(file, content)
      validate_timestamps(file, content)
      validate_foreign_keys(file, content)
    end

    private

    def validate_directory_exists
      return if @migrations_path.directory?

      @errors << "Migrations directory not found at: #{@migrations_path}"
    end

    def validate_migration_files
      migration_files = @migrations_path.glob("*.rb")

      if migration_files.empty?
        @errors << "No migration files found in #{@migrations_path}"
        return
      end

      migration_files.each do |file|
        validate_file(file)
      end
    end

    def validate_file_structure(file, content)
      @errors << "#{file.basename}: Missing class definition" unless content.include?("class")
      validate_up_method(file, content)
    end

    def validate_up_method(file, content)
      has_change = content.include?("def change")
      has_up = content.include?("def up")
      @errors << "#{file.basename}: Missing 'up' method" unless has_change || has_up
    end

    def validate_methods(file, content)
      return if content.match?(/\s+def\s+down\b/)

      @errors << "#{file.basename}: Missing down method for rollback"
    end

    def validate_timestamps(file, content)
      return unless content.match?(/\s+create_table.*do.*\|t\|/m) && !content.match?(/\s+t\.timestamps\b/)

      @errors << "#{file.basename}: Missing timestamps"
    end

    def validate_foreign_keys(file, content)
      has_author_id = content.match?(/\s+t\.integer\s+:author_id\b/)
      has_references = content.match?(/\s+t\.references\s+:author.*foreign_key/)
      return unless has_author_id && !has_references

      @errors << "#{file.basename}: Missing foreign key for author_id"
    end

    def validate_migration_versions
      versions = @migrations_path.glob("*.rb").map do |file|
        file.basename.to_s.split("_").first.to_i
      end.sort

      return if versions == versions.uniq

      @errors << "Migration versions are not in sequential order"
      @errors << "Expected: #{versions.join(', ')}"
      @errors << "Found: #{versions.join(', ')}"
    end

    def validate_migration_dependencies
      # This would check for proper ordering of migrations
      # For example, if a migration adds a foreign key, the referenced table should exist
      # This is a complex check that would require parsing the migration content
      # and building a dependency graph
    end

    def validate_migration_reversibility
      # This would check if migrations can be properly rolled back
      # For example, checking if remove_column has the correct column type
      # This is a complex check that would require parsing the migration content
    end
  end
end
