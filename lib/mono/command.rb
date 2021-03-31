# frozen_string_literal: true

module Mono
  class Command
    attr_reader :command

    def initialize(command)
      @command = command
    end

    def execute
      puts command
      unless dry_run?
        system command
        exitstatus = $?
        unless exitstatus.success?
          puts "Error: Command failed with #{exitstatus.exitstatus}"
          exit 1
        end
      end
    end

    def dry_run?
      ENV["DRY_RUN"] == "true"
    end

    module Helper
      def run_command(command)
        Command.new(command).execute
      end
    end
  end
end
