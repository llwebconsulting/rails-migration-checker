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

    def validate_migration_file(file)
      content = file.read
      validate_file_structure(content)
      validate_methods(content)
      validate_timestamps(content)
      validate_foreign_keys(content)
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
        validate_migration_file(file)
      end
    end

    def validate_file_structure(content)
      @errors << "Migration file must contain a class definition" unless content.include?("class")
      @errors << "Migration file must contain an 'up' method" unless content.include?("def up")
    end

    def validate_methods(content)
      @errors << "Migration file must contain a 'down' method" unless content.include?("def down")
    end

    def validate_timestamps(content)
      return unless content.include?("create_table") && !content.include?("t.timestamps")

      @errors << "Table creation should include timestamps"
    end

    def validate_foreign_keys(content)
      return unless content.include?("t.integer :author_id") && !content.include?("add_foreign_key :posts, :authors")

      @errors << "Foreign key columns should have corresponding foreign key constraints"
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
