# frozen_string_literal: true

require "pathname"
require "set"

# Rake tasks for fixing migration issues
module Migrations
  module Tasks
    # Module containing tasks for fixing common migration issues
    # Provides tasks for adding missing down methods, timestamps, and foreign keys
    module Fix
      extend TaskHelpers

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

      desc "Fix migrations missing timestamps"
      task fix_missing_timestamps: :environment do
        migration_files = migrations_path.glob("*.rb")

        migration_files.each do |file|
          content = file.read
          next unless content.include?("create_table") && !content.include?("t.timestamps")

          backup_file = file.sub_ext(".rb.bak")
          FileUtils.cp(file, backup_file)

          content = content.gsub(/end\n\z/, <<~RUBY)
                t.timestamps
              end
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
    end
  end
end
