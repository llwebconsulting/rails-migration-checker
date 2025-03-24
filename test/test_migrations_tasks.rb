require "test_helper"
require "tempfile"
require "pathname"
require "fileutils"

module Migrations
  class TestTasks < Minitest::Test
    include TestRakeSetup

    def setup
      super
      @temp_dir = Pathname.new(Dir.mktmpdir)
      @migrations_dir = @temp_dir.join("db/migrate")
      FileUtils.mkdir_p(@migrations_dir)
      
      # Set the migrations path for testing
      ENV["MIGRATIONS_PATH"] = @migrations_dir.to_s
      
      # Create some test migrations
      create_migration("20240101000000_create_users.rb", <<~RUBY)
        class CreateUsers < ActiveRecord::Migration[7.0]
          def up
            create_table :users do |t|
              t.string :name
            end
          end
        end
      RUBY
      
      create_migration("20240101000001_create_posts.rb", <<~RUBY)
        class CreatePosts < ActiveRecord::Migration[7.0]
          def up
            create_table :posts do |t|
              t.string :title
              t.integer :user_id
            end
            add_column :posts, :author_id, :integer
          end
        end
      RUBY
    end

    def teardown
      FileUtils.remove_entry(@temp_dir)
      ENV.delete("MIGRATIONS_PATH")
    end

    def test_fix_missing_down
      task = Rake::Task["migrations:fix_missing_down"]
      task.invoke
      
      # Check that backup was created
      assert File.exist?(@migrations_dir.join("20240101000000_create_users.rb.bak"))
      
      # Check that down method was added
      content = File.read(@migrations_dir.join("20240101000000_create_users.rb"))
      assert_includes content, "def down"
      assert_includes content, "drop_table :users"
    end

    def test_fix_missing_timestamps
      task = Rake::Task["migrations:fix_missing_timestamps"]
      task.invoke
      
      # Check that backup was created
      assert File.exist?(@migrations_dir.join("20240101000000_create_users.rb.bak"))
      
      # Check that timestamps were added
      content = File.read(@migrations_dir.join("20240101000000_create_users.rb"))
      assert_includes content, "t.timestamps"
    end

    def test_fix_missing_foreign_keys
      task = Rake::Task["migrations:fix_missing_foreign_keys"]
      task.invoke
      
      # Check that backup was created
      assert File.exist?(@migrations_dir.join("20240101000001_create_posts.rb.bak"))
      
      # Check that foreign keys were added
      content = File.read(@migrations_dir.join("20240101000001_create_posts.rb"))
      assert_includes content, "add_foreign_key :posts, :users"
      assert_includes content, "add_foreign_key :posts, :authors"
    end

    def test_analyze_dependencies
      task = Rake::Task["migrations:analyze_dependencies"]
      task.invoke
      
      # The test should not raise any errors
      assert true # Just checking that it runs without errors for now
    end

    def test_backup_plan
      task = Rake::Task["migrations:backup_plan"]
      task.invoke
      
      # Check that backup directory was created
      backup_dir = @temp_dir.join("db/migrate_backups")
      assert backup_dir.directory?
      
      # Check that backup files were created
      backup_files = backup_dir.glob("**/*.rb")
      assert_equal 2, backup_files.length
    end

    private

    def create_migration(filename, content)
      File.write(@migrations_dir.join(filename), content)
    end
  end
end 