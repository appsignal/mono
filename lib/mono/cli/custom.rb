# frozen_string_literal: true

module Mono
  module Cli
    class Custom < Base
      def initialize(command, options = {})
        @command = command
        super(options)
      end

      def execute
        parallel = parallel?
        mode = parallel ? " in parallel" : ""
        puts "Custom command for project#{mode}"
        run_hooks("custom", "pre")
        threads = []
        packages.each do |package|
          if parallel
            threads <<
              Thread.new do
                run_command_in_package(package)
              end
          else
            run_command_in_package(package)
          end
        end
        threads.each(&:join)
        run_hooks("custom", "post")
      rescue Interrupt
        puts "Cleaning up..."
        threads.each(&:kill)
        raise
      end

      private

      def run_command_in_package(package)
        puts "# Custom command for package: #{package.name} (#{package.path})"
        package.run_custom_command @command.join(" ")
      end
    end
  end
end
