# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "pathname"

module Migrations
  class TestMigrationsTasks < Minitest::Test
    include TestRakeSetup

    def setup
      super
      setup_temp_directory
      setup_migrations
    end

    def teardown
      super
      FileUtils.remove_entry(@temp_dir) if @temp_dir&.exist?
    end

    private

    def setup_temp_directory
      @temp_dir = Pathname.new(Dir.mktmpdir)
      @migrations_dir = @temp_dir.join("db/migrate")
      FileUtils.mkdir_p(@migrations_dir)
      ENV["MIGRATIONS_PATH"] = @migrations_dir.to_s
    end

    def setup_migrations
      create_users_migration
      create_posts_migration
      create_comments_migration
    end

    def create_users_migration
      write_migration("20240101000000_create_users.rb", <<~RUBY)
        class CreateUsers < ActiveRecord::Migration[7.0]
          def up
            create_table :users do |t|
              t.string :name
              t.timestamps
            end
          end

          def down
            drop_table :users
          end
        end
      RUBY
    end

    def create_posts_migration
      write_migration("20240101000001_create_posts.rb", <<~RUBY)
        class CreatePosts < ActiveRecord::Migration[7.0]
          def up
            create_table :posts do |t|
              t.string :title
              t.text :content
              t.integer :author_id
              t.timestamps
            end

            add_foreign_key :posts, :users, column: :author_id
          end

          def down
            drop_table :posts
          end
        end
      RUBY
    end

    def create_comments_migration
      write_migration("20240101000002_create_comments.rb", <<~RUBY)
        class CreateComments < ActiveRecord::Migration[7.0]
          def up
            create_table :comments do |t|
              t.text :content
              t.integer :post_id
              t.integer :author_id
              t.timestamps
            end

            add_foreign_key :comments, :posts
            add_foreign_key :comments, :users, column: :author_id
          end

          def down
            drop_table :comments
          end
        end
      RUBY
    end

    def write_migration(filename, content)
      File.write(@migrations_dir.join(filename), content)
    end
  end
end
