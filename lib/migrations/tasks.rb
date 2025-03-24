# frozen_string_literal: true

require "pathname"

# Rake tasks for the Migrations gem
module Migrations
  # Tasks module that loads and defines rake tasks
  module Tasks
    module_function

    def load_tasks
      load File.expand_path("tasks.rake", __dir__)
    end
  end
end
