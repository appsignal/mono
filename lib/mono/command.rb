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

      puts cmd
      unless dry_run?
        system cmd
        exitstatus = $?
        unless exitstatus.success?
          puts "Error: Command failed with #{exitstatus.exitstatus}"
          exit 1
        end
      end
    end

    private

    def dry_run?
      ENV["DRY_RUN"] == "true"
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
