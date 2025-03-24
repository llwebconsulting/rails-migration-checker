require "rake"

module Migrations
  module Tasks
    def self.load_tasks
      load File.expand_path("../tasks.rake", __FILE__)
    end
  end
end 