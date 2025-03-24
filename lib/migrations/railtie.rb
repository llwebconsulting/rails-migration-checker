# frozen_string_literal: true

require "rails"

# Rails integration for the Migrations gem
module Migrations
  # Railtie class that integrates the gem with Rails
  class Railtie < Rails::Railtie
    rake_tasks do
      load "migrations/tasks.rake"
    end
  end
end
