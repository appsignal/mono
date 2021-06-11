# frozen_string_literal: true

module Mono
  class Command
    attr_reader :command, :options

    def initialize(command, options = {})
      @command = command
      @options = options
    end

    def execute
      # Navigate to path if a path is specified
      options = {}
      options[:chdir] = path if path

      env = {}
      ENV.each do |key, value|
        env[key] =
          if key.start_with?("npm_")
            nil
          else
            value
          end
      end
      puts "new_env:"
      pp env
      puts command
      unless dry_run?
        pid = spawn(env, command)
        _pid, status = Process.wait2(pid)
        unless status.exitstatus == 0
          puts "Error: Command failed with #{status.exitstatus}"
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
