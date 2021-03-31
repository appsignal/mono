# frozen_string_literal: true

module Mono
  module Cli
    class Build < Base
      def execute
        exit_cli "No packages found!" unless packages.any?

        run_hooks("build", "pre")
        puts "# Building packages"
        packages.each do |package|
          puts "# Build package: #{package.name} (#{package.path})"
          package.build
        end
        run_hooks("build", "post")
      end
    end
  end
end
