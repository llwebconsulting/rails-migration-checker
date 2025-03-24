require "thor"
require_relative "version"

module Migrations
  class CLI < Thor
    package_name "migrations"
    map "-v" => :version

    desc "version", "Show the version"
    def version
      puts "migrations #{VERSION}"
    end

    desc "validate [MIGRATIONS_PATH]", "Validate Rails migrations in the specified path"
    method_option :strict, type: :boolean, default: false, desc: "Enable strict validation mode"
    
    def validate(migrations_path = "db/migrate")
      begin
        Migrations.validate(migrations_path)
        puts "✅ All migrations are valid!"
      rescue Error => e
        puts "❌ Migration validation failed: #{e.message}"
        exit 1
      end
    end

    default_task :validate
  end
end 