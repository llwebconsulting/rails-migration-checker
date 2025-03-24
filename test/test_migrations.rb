# frozen_string_literal: true

require "test_helper"
require "migrations/validator"
require "tempfile"
require "pathname"
require "fileutils"
require "pry-byebug"

module Migrations
  class TestValidator < Minitest::Test
    def setup
      @temp_dir = Pathname.new(Dir.mktmpdir)
      @migrations_dir = @temp_dir.join("db/migrate")
      FileUtils.mkdir_p(@migrations_dir)
      @validator = Validator.new(@migrations_dir)
    end

    def teardown
      FileUtils.remove_entry(@temp_dir) if @temp_dir&.exist?
    end

    def test_validates_directory_exists
      FileUtils.remove_entry(@migrations_dir)
      assert_raises(Error) do
        @validator.validate
      end
    end

    def test_validates_migration_files
      create_test_migrations

      @validator.validate

      assert_empty @validator.errors
    end

    def test_detects_missing_down_method
      create_test_migrations_without_down
      begin
        @validator.validate
      rescue Error
        # Expected error
      end

      assert_includes @validator.errors, "20240101000000_create_users.rb: Missing down method for rollback"
    end

    def test_detects_missing_timestamps
      create_test_migrations_without_timestamps
      begin
        @validator.validate
      rescue Error
        # Expected error
      end

      assert_includes @validator.errors, "20240101000000_create_users.rb: Missing timestamps"
    end

    def test_detects_missing_foreign_keys
      create_test_migrations_without_foreign_keys
      begin
        @validator.validate
      rescue Error
        # Expected error
      end

      assert_includes @validator.errors, "20240101000001_create_posts.rb: Missing foreign key for author_id"
    end

    def test_valid_migration
      @validator.validate_file(@valid_migration)

      assert_empty @validator.errors
    end

    def test_missing_down_method
      @validator.validate_file(@missing_down_migration)

      assert_includes @validator.errors, "20240101000000_create_users.rb: Missing down method for rollback"
    end

    def test_missing_timestamps
      @validator.validate_file(@missing_timestamps_migration)

      assert_includes @validator.errors, "20240101000000_create_users.rb: Missing timestamps"
    end

    def test_missing_foreign_key
      @validator.validate_file(@missing_foreign_key_migration)

      assert_includes @validator.errors, "20240101000001_create_posts.rb: Missing foreign key for author_id"
    end

    private

    def create_test_migrations
      create_users_migration
      create_posts_migration
    end

    def create_test_migrations_without_down
      create_users_migration_without_down
      create_posts_migration
    end

    def create_test_migrations_without_timestamps
      create_users_migration_without_timestamps
      create_posts_migration
    end

    def create_test_migrations_without_foreign_keys
      create_users_migration
      create_posts_migration_without_foreign_keys
    end

    def create_users_migration
      content = <<~RUBY
        class CreateUsers < ActiveRecord::Migration[7.0]
          def change
            create_table :users do |t|
              t.string :name
              t.string :email
              t.timestamps
            end
          end

          def down
            drop_table :users
          end
        end
      RUBY
      write_migration("20240101000000_create_users.rb", content)
    end

    def create_users_migration_without_down
      content = <<~RUBY
        class CreateUsers < ActiveRecord::Migration[7.0]
          def change
            create_table :users do |t|
              t.string :name
              t.string :email
              t.timestamps
            end
          end
        end
      RUBY
      write_migration("20240101000000_create_users.rb", content)
    end

    def create_users_migration_without_timestamps
      content = <<~RUBY
        class CreateUsers < ActiveRecord::Migration[7.0]
          def change
            create_table :users do |t|
              t.string :name
              t.string :email
            end
          end

          def down
            drop_table :users
          end
        end
      RUBY
      write_migration("20240101000000_create_users.rb", content)
    end

    def create_posts_migration
      content = <<~RUBY
        class CreatePosts < ActiveRecord::Migration[7.0]
          def change
            create_table :posts do |t|
              t.string :title
              t.text :content
              t.references :author, foreign_key: { to_table: :users }
              t.timestamps
            end
          end

          def down
            drop_table :posts
          end
        end
      RUBY
      write_migration("20240101000001_create_posts.rb", content)
    end

    def create_posts_migration_without_foreign_keys
      content = <<~RUBY
        class CreatePosts < ActiveRecord::Migration[7.0]
          def change
            create_table :posts do |t|
              t.string :title
              t.text :content
              t.integer :author_id
              t.timestamps
            end
          end

          def down
            drop_table :posts
          end
        end
      RUBY
      write_migration("20240101000001_create_posts.rb", content)
    end

    def write_migration(filename, content)
      file = @migrations_dir.join(filename)
      FileUtils.mkdir_p(@migrations_dir)
      File.write(file, content)
    end
  end
end
