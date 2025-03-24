require "active_record"
require "pathname"

module Migrations
  class Validator
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

    private

    def validate_directory_exists
      unless @migrations_path.directory?
        @errors << "Migrations directory not found at: #{@migrations_path}"
      end
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

    def validate_migration_file(file)
      content = file.read
      
      # Check for common issues
      if content.include?("drop_table") && !content.include?("create_table")
        @errors << "#{file.basename}: Found drop_table without corresponding create_table"
      end

      if content.include?("remove_column") && !content.include?("add_column")
        @errors << "#{file.basename}: Found remove_column without corresponding add_column"
      end

      # Check for missing down method
      unless content.include?("def down")
        @errors << "#{file.basename}: Missing down method for rollback"
      end
    end

    def validate_migration_versions
      versions = @migrations_path.glob("*.rb").map do |file|
        file.basename.to_s.split("_").first.to_i
      end.sort

      # Check for duplicate versions
      if versions.uniq.length != versions.length
        @errors << "Duplicate migration versions found"
      end

      # Check for gaps in versions
      versions.each_with_index do |version, index|
        if index > 0 && version != versions[index - 1] + 1
          @errors << "Gap in migration versions between #{versions[index - 1]} and #{version}"
        end
      end
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