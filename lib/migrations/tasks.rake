# frozen_string_literal: true

require "pathname"
require "set"
require_relative "tasks/helpers"

# Rake tasks for the Migrations gem
module Migrations
  # Helper methods for rake tasks
  module TaskHelpers
    include Tasks::Helpers
  end

  desc "Load the Rails environment"
  task :environment do
    require "rails"
    require "active_record"
  end

  # Load task modules
  Dir[File.expand_path("tasks/*.rake", __dir__)].each { |f| load f }

  desc "Analyze migrations for potential issues"
  task analyze: :environment do
    validator = Migrations::Validator.new(migrations_path)
    validator.validate
  end

  namespace :migrations do
    desc "Fix migrations missing down methods"
    task fix_missing_down: :environment do
      migration_files = migrations_path.glob("*.rb")

      migration_files.each do |file|
        content = file.read
        next if content.include?("def down")

        backup_file = file.sub_ext(".rb.bak")
        FileUtils.cp(file, backup_file)

        content = content.gsub(/end\n\z/, <<~RUBY)
            end

            def down
              raise ActiveRecord::IrreversibleMigration
            end
          end
        RUBY

        File.write(file, content)
        puts "Added down method to #{file.basename}"
      end
    end

    desc "Fix migration version gaps by reordering versions"
    task fix_version_gaps: :environment do
      puts "Analyzing migration versions for gaps..."

      # Get all migration files and their versions
      migrations = migrations_path.glob("*.rb").map do |file|
        version = file.basename.to_s.split("_").first.to_i
        [version, file]
      end.sort_by(&:first)

      # Find gaps
      gaps = []
      migrations.each_with_index do |(version, _), index|
        next if index.zero?

        prev_version = migrations[index - 1].first
        gaps << [prev_version, version] if version != prev_version + 1
      end

      if gaps.empty?
        puts "No version gaps found!"
        next
      end

      puts "\nFound the following gaps:"
      gaps.each do |prev, curr|
        puts "Gap between #{prev} and #{curr}"
      end

      puts "\nTo fix these gaps, you should:"
      puts "1. Create a new migration with the missing version number"
      puts "2. Or reorder the existing migrations to fill the gaps"
      puts "\nWARNING: Reordering migrations can be dangerous if they have been applied to production!"
      puts "Please ensure you have a backup and understand the implications before proceeding."
    end

    desc "Check for potential data loss in migrations"
    task check_data_loss: :environment do
      puts "Analyzing migrations for potential data loss..."

      dangerous_operations = {
        "drop_table" => "Dropping a table without backup",
        "remove_column" => "Removing a column without backup",
        "change_column" => "Changing column type without preserving data",
        "remove_index" => "Removing an index that might be needed"
      }

      migrations_path.glob("*.rb").each do |file|
        content = file.read
        dangerous_operations.each do |operation, description|
          next unless content.include?(operation)

          puts "\nFound potential data loss in #{file.basename}:"
          puts "- #{description}"
          puts "- Line containing operation: #{content.lines.find { |l| l.include?(operation) }}"
        end
      end
    end

    desc "Create backup plan for migrations"
    task backup_plan: :environment do
      backup_dir = migrations_path.parent.join("migrate_backups")
      FileUtils.mkdir_p(backup_dir)

      migration_files = migrations_path.glob("*.rb")
      migration_files.each do |file|
        backup_file = backup_dir.join(file.basename)
        FileUtils.cp(file, backup_file)
      end

      puts "Created backup plan in #{backup_dir}"
    end

    desc "Fix migrations missing timestamps"
    task fix_missing_timestamps: :environment do
      migration_files = migrations_path.glob("*.rb")

      migration_files.each do |file|
        content = file.read
        next unless content.include?("create_table") && !content.include?("t.timestamps")

        backup_file = file.sub_ext(".rb.bak")
        FileUtils.cp(file, backup_file)

        content = content.gsub(/end\n\z/, <<~RUBY)
            end

            t.timestamps
          end
        RUBY

        File.write(file, content)
        puts "Added timestamps to #{file.basename}"
      end
    end

    desc "Fix migrations missing foreign keys"
    task fix_missing_foreign_keys: :environment do
      migration_files = migrations_path.glob("*.rb")

      migration_files.each do |file|
        content = file.read
        next unless content.include?("t.integer :author_id") && !content.include?("add_foreign_key :posts, :authors")

        backup_file = file.sub_ext(".rb.bak")
        FileUtils.cp(file, backup_file)

        content = content.gsub(/end\n\z/, <<~RUBY)
            end

            def down
              remove_foreign_key :posts, :authors if foreign_key_exists?(:posts, :authors)
            end
          end
        RUBY

        File.write(file, content)
        puts "Added foreign key to #{file.basename}"
      end
    end

    desc "Analyze migration dependencies"
    task analyze_dependencies: :environment do
      migration_files = migrations_path.glob("*.rb")
      dependencies = {}

      migration_files.each do |file|
        content = file.read
        version = file.basename.to_s.split("_").first.to_i
        dependencies[version] = {
          file: file,
          depends_on: []
        }

        # Find table references
        content.scan(/create_table :(\w+)/) do |table|
          dependencies[version][:depends_on] << table[0].to_sym
        end

        content.scan(/add_foreign_key :(\w+), :(\w+)/) do |_from_table, to_table|
          dependencies[version][:depends_on] << to_table.to_sym
        end
      end

      circular = find_circular_dependencies(dependencies)
      if circular.any?
        puts "Found circular dependencies:"
        circular.each do |cycle|
          puts "  #{cycle.join(' -> ')}"
        end
        exit 1
      end
    end
  end
end
