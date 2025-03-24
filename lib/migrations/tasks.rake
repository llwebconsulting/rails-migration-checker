require "pathname"
require "fileutils"
require "set"

task :environment do
  # This task is just a placeholder for Rails environment loading
  # In a Rails app, this would load the Rails environment
end

namespace :migrations do
  def migrations_path
    Pathname.new(ENV["MIGRATIONS_PATH"] || "db/migrate")
  end

  desc "Analyze migrations for potential issues"
  task analyze: :environment do
    validator = Migrations::Validator.new(migrations_path)
    validator.validate
  end

  desc "Fix missing down methods by adding a safe default"
  task fix_missing_down: :environment do
    puts "Analyzing migrations for missing down methods..."
    
    migrations_path.glob("*.rb").each do |file|
      content = file.read
      next if content.include?("def down")
      
      puts "\nFound migration without down method: #{file.basename}"
      puts "Current content:"
      puts content
      
      # Create a backup of the original file
      backup_file = file.sub_ext(".rb.bak")
      FileUtils.cp(file, backup_file)
      puts "\nCreated backup at: #{backup_file}"
      
      # Add a safe down method based on the up method
      new_content = content.gsub(/end\s*$/, "")
      new_content += "\n\n  def down\n"
      
      # Analyze the up method to create a safe down
      if content.include?("create_table")
        new_content += "    drop_table :#{content.match(/create_table :(\w+)/)[1]}\n"
      elsif content.include?("add_column")
        table = content.match(/add_column :(\w+)/)[1]
        column = content.match(/add_column :\w+, :(\w+)/)[1]
        new_content += "    remove_column :#{table}, :#{column}\n"
      elsif content.include?("add_index")
        table = content.match(/add_index :(\w+)/)[1]
        columns = content.match(/add_index :\w+, :(\w+)/)[1]
        new_content += "    remove_index :#{table}, :#{columns}\n"
      else
        new_content += "    raise ActiveRecord::IrreversibleMigration\n"
      end
      
      new_content += "  end\nend"
      
      # Write the new content
      File.write(file, new_content)
      puts "Added safe down method to #{file.basename}"
      puts "Please review the changes before committing!"
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
      next if index == 0
      prev_version = migrations[index - 1].first
      if version != prev_version + 1
        gaps << [prev_version, version]
      end
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
        if content.include?(operation)
          puts "\nFound potential data loss in #{file.basename}:"
          puts "- #{description}"
          puts "- Line containing operation: #{content.lines.find { |l| l.include?(operation) }}"
        end
      end
    end
  end

  desc "Generate a migration backup plan"
  task backup_plan: :environment do
    puts "Generating migration backup plan..."
    
    backup_dir = migrations_path.parent.join("migrate_backups")
    backup_dir.mkdir unless backup_dir.exist?
    
    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    backup_path = backup_dir.join("backup_#{timestamp}")
    backup_path.mkdir
    
    migrations_path.glob("*.rb").each do |file|
      backup_file = backup_path.join(file.basename)
      FileUtils.cp(file, backup_file)
      puts "Backed up #{file.basename} to #{backup_file}"
    end
    
    puts "\nBackup completed in: #{backup_path}"
    puts "Please store this backup in a safe location!"
  end

  desc "Fix missing timestamps in tables"
  task fix_missing_timestamps: :environment do
    puts "Analyzing migrations for missing timestamps..."
    
    migrations_path.glob("*.rb").each do |file|
      content = file.read
      next unless content.include?("create_table")
      
      table_name = content.match(/create_table :(\w+)/)[1]
      unless content.include?("t.timestamps")
        puts "\nFound table without timestamps: #{table_name} in #{file.basename}"
        
        # Create a backup
        backup_file = file.sub_ext(".rb.bak")
        FileUtils.cp(file, backup_file)
        puts "Created backup at: #{backup_file}"
        
        # Add timestamps
        new_content = content.gsub(/end\s*$/, "")
        new_content += "\n      t.timestamps\n"
        new_content += "    end\nend"
        
        File.write(file, new_content)
        puts "Added timestamps to #{table_name}"
        puts "Please review the changes before committing!"
      end
    end
  end

  desc "Fix missing foreign key constraints"
  task fix_missing_foreign_keys: :environment do
    puts "Analyzing migrations for missing foreign key constraints..."
    
    migrations_path.glob("*.rb").each do |file|
      content = file.read
      foreign_keys_to_add = []
      
      # Find potential foreign key columns in create_table blocks
      content.scan(/create_table :(\w+).*?end/m).each do |table_match|
        table = table_match[0]
        content.scan(/t\.(?:integer|bigint|references) :(\w+)_id/).each do |column_match|
          referenced_table = column_match[0].pluralize
          unless content.include?("add_foreign_key :#{table}, :#{referenced_table}")
            foreign_keys_to_add << [table, referenced_table]
          end
        end
      end
      
      # Find potential foreign key columns in add_column statements
      content.scan(/add_column :(\w+), :(\w+)_id/).each do |table, column|
        referenced_table = column.pluralize
        unless content.include?("add_foreign_key :#{table}, :#{referenced_table}")
          foreign_keys_to_add << [table, referenced_table]
        end
      end
      
      if foreign_keys_to_add.any?
        puts "\nFound potential missing foreign keys in: #{file.basename}"
        foreign_keys_to_add.each do |table, referenced_table|
          puts "  - #{table}.#{referenced_table}_id -> #{referenced_table}"
        end
        
        # Create a backup
        backup_file = file.sub_ext(".rb.bak")
        FileUtils.cp(file, backup_file)
        puts "Created backup at: #{backup_file}"
        
        # Add all foreign key constraints
        new_content = content.gsub(/end\s*$/, "")
        foreign_keys_to_add.each do |table, referenced_table|
          new_content += "\n    add_foreign_key :#{table}, :#{referenced_table}"
        end
        new_content += "\n  end\nend"
        
        File.write(file, new_content)
        puts "Added foreign key constraints"
        puts "Please review the changes before committing!"
      end
    end
  end

  desc "Analyze migration dependencies"
  task analyze_dependencies: :environment do
    puts "Analyzing migration dependencies..."
    
    # Build dependency graph
    dependencies = {}
    migrations_path.glob("*.rb").each do |file|
      content = file.read
      version = file.basename.to_s.split("_").first
      
      # Find table references
      tables = content.scan(/create_table :(\w+)/).flatten
      references = content.scan(/add_foreign_key :(\w+), :(\w+)/).flatten
      
      dependencies[version] = {
        file: file,
        tables: tables,
        references: references,
        depends_on: []
      }
    end
    
    # Analyze dependencies
    dependencies.each do |version, info|
      info[:references].each do |ref|
        # Find which migration created this table
        table_creator = dependencies.find { |_, d| d[:tables].include?(ref) }
        if table_creator
          info[:depends_on] << table_creator[0]
        end
      end
    end
    
    # Report issues
    puts "\nMigration Dependencies:"
    dependencies.each do |version, info|
      if info[:depends_on].any?
        puts "\n#{version} depends on:"
        info[:depends_on].each do |dep|
          puts "  - #{dep}"
        end
      end
    end
    
    # Check for circular dependencies
    circular = find_circular_dependencies(dependencies)
    if circular.any?
      puts "\nWARNING: Found circular dependencies:"
      circular.each do |cycle|
        puts "  #{cycle.join(' -> ')}"
      end
    end
  end

  private

  def find_circular_dependencies(dependencies)
    circular = []
    visited = Set.new
    path = []
    
    dependencies.each do |version, info|
      next if visited.include?(version)
      dfs(version, dependencies, visited, path, circular)
    end
    
    circular
  end

  def dfs(version, dependencies, visited, path, circular)
    return if visited.include?(version)
    
    visited.add(version)
    path << version
    
    dependencies[version][:depends_on].each do |dep|
      if path.include?(dep)
        cycle = path[path.index(dep)..-1] + [dep]
        circular << cycle unless circular.include?(cycle)
      else
        dfs(dep, dependencies, visited, path, circular)
      end
    end
    
    path.pop
  end
end 