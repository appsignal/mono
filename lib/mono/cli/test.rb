# frozen_string_literal: true

module Mono
  module Cli
    class Test < Base
      def execute
        puts "Testing project"
        run_hooks("test", "pre")
        packages.each do |package|
          puts "# Testing package: #{package.name} (#{package.path})"
          package.test
        rescue NoSuchCommandError
          puts "Command not configured. " \
            "Skipped command for #{package.name} (#{package.path})"
        end
        run_hooks("test", "post")
      end
    end
  end
end
