require "test_helper"
require "migrations/validator"
require "tempfile"
require "pathname"

module Migrations
  class TestValidator < Minitest::Test
    def setup
      @temp_dir = Pathname.new(Dir.mktmpdir)
      @validator = Validator.new(@temp_dir)
    end

    def teardown
      FileUtils.remove_entry(@temp_dir)
    end

    def test_validates_directory_exists
      assert_raises(Error) do
        @validator.validate
      end
    end

    def test_validates_migration_files
      FileUtils.mkdir_p(@temp_dir)
      
      # Create a valid migration
      create_migration("20240101000000_create_users.rb", <<~RUBY)
        class CreateUsers < ActiveRecord::Migration[7.0]
          def up
            create_table :users do |t|
              t.string :name
            end
          end

          def down
            drop_table :users
          end
        end
      RUBY

      # Should not raise an error for valid migration
      assert_nothing_raised do
        @validator.validate
      end

      # Create an invalid migration (missing down method)
      create_migration("20240101000001_add_email_to_users.rb", <<~RUBY)
        class AddEmailToUsers < ActiveRecord::Migration[7.0]
          def up
            add_column :users, :email, :string
          end
        end
      RUBY

      # Should raise an error for invalid migration
      assert_raises(Error) do
        @validator.validate
      end
    end

    private

    def create_migration(filename, content)
      File.write(@temp_dir.join(filename), content)
    end
  end
end 