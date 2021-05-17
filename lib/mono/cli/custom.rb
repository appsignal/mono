# frozen_string_literal: true

module Mono
  module Cli
    class Custom < Base
      def initialize(command, options = {})
        @command = command
        super(options)
      end

      def execute
        puts "Custom command for project"
        run_hooks("custom", "pre")
        packages.each do |package|
          puts "# Custom command for package: #{package.name} (#{package.path})"
          chdir package.path do
            run_command @command.join(" ")
          end
        end
        run_hooks("custom", "post")
      end
    end
  end
end
