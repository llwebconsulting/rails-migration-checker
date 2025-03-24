# frozen_string_literal: true

require "pathname"
require "set"

# Rake tasks for analyzing migrations
module Migrations
  module Tasks
    # Module containing tasks for analyzing migrations
    # Provides tasks for analyzing dependencies and creating backup plans
    module Analyze
      extend TaskHelpers

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
    end
  end
end
