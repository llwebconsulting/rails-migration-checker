# frozen_string_literal: true

require "pathname"
require "set"

module Migrations
  module Tasks
    # Helper methods for rake tasks
    module Helpers
      def migrations_path
        Pathname.new(ENV["MIGRATIONS_PATH"] || "db/migrate")
      end

      def find_circular_dependencies(dependencies)
        circular = []
        visited = Set.new
        path = []

        dependencies.each_key do |version|
          next if visited.include?(version)

          dfs(version, dependencies, visited, path, circular)
        end

        circular
      end

      def dfs(version, dependencies, visited, path, circular)
        return if visited.include?(version)

        visited.add(version)
        path << version

        dependencies[version][:depends_on].each do |dep|
          if path.include?(dep)
            cycle = path[path.index(dep)..] + [dep]
            circular << cycle unless circular.include?(cycle)
          else
            dfs(dep, dependencies, visited, path, circular)
          end
        end

        path.pop
      end
    end
  end
end
