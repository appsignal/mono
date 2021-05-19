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
          package.run_custom_command @command.join(" ")
        end
        run_hooks("custom", "post")
      end
    end
  end
end
