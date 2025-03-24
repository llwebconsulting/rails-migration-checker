# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "migrations"
require "minitest/autorun"
require "active_record"
require "rake"
require "rails/all"

# Create a minimal Rails application for testing
module TestApp
  class Application < Rails::Application
    config.root = File.expand_path("../", __dir__)
    config.eager_load = false
    config.active_record.maintain_test_schema = false
    config.active_record.verify_foreign_keys_for_fixtures = false
    config.active_record.dump_schema_after_migration = false
    config.active_record.migration_error = :page_load
    config.active_record.warn_on_records_fetched_greater_than = false
  end
end

Rails.application.initialize!

# Load rake tasks
module TestRakeSetup
  def setup
    super
    Rake.application = Rake::Application.new
    Rake::Task.clear
    load File.expand_path("../../lib/migrations/tasks.rake", __dir__)
  end

  def teardown
    super
    Rake.application = nil
  end
end
