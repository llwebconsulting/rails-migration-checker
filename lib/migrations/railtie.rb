require "rails"

module Migrations
  class Railtie < Rails::Railtie
    rake_tasks do
      load "migrations/tasks.rake"
    end
  end
end 