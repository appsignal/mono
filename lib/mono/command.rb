# frozen_string_literal: true

module Mono
  class Command
    attr_reader :command, :options

    def initialize(command, options = {})
      @command = command
      @options = options
    end

    def execute
      parts = []
      # Navigate to path if a path is specified
      parts << "cd #{path} && " if path
      parts << command
      cmd = parts.join

      execute_command cmd unless dry_run?
    end

    private

    def execute_command(cmd)
      loop do
        puts cmd
        system cmd
        exitstatus = $?
        break if exitstatus.success?

        if retry?
          answer = Shell.yes_or_no(
            "Error: Command failed. Do you want to retry? (Y/n): ",
            :default => "Y"
          )
          next if answer
        end

        puts "Error: Command failed with status `#{exitstatus.exitstatus}`"
        exit 1
      end
    end

    def dry_run?
      ENV["DRY_RUN"] == "true"
    end

    def retry?
      options[:retry]
    end

    def path
      dir = options[:dir]
      dir if dir && dir != "."
    end

    module Helper
      def run_command(command, options = {})
        Command.new(command, options).execute
      end
    end
  end
end
