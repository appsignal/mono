# frozen_string_literal: true

module Mono
  module Cli
    class Clean < Base
      def execute
        puts "Cleaning project"
        run_hooks("clean", "pre")
        language.clean
        packages.each do |package|
          puts "# Cleaning package: #{package.name} (#{package.path})"
          package.clean
        end
        run_hooks("clean", "post")
      end
    end
  end
end
