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
        end
        run_hooks("test", "post")
      end
    end
  end
end
