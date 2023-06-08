# frozen_string_literal: true

module Mono
  class Command
    attr_reader :command, :options

    def initialize(command, options = {})
      @command = command
      @options = options
    end

    def execute
      execute_command command unless dry_run?
    end

    private

    def execute_command(cmd)
      loop do
        opts = {}
        opts[:chdir] = path if path
        if options[:capture]
          read, write = IO.pipe
          opts[[:out, :err]] = write
        end
        puts cmd if options.fetch(:print_command, true)
        pid = Process.spawn(
          options.fetch(:env, {}),
          cmd,
          opts
        )
        _pid, exitstatus = Process.wait2(pid)
        break read_output(read, write) if exitstatus.success?

        if retry?
          answer = Shell.yes_or_no(
            "Error: Command failed. Do you want to retry? (Y/n): ",
            :default => "Y"
          )
          next if answer
        end

        raise Mono::Error,
          "Command failed with status `#{exitstatus.exitstatus}`"
      end
    end

    def read_output(read, write)
      return unless read

      begin
        write.close
        read.read
      rescue IOError # rubocop:disable Lint/SuppressedException
      ensure
        read.close
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
