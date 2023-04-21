# frozen_string_literal: true

module Mono
  class Command
    attr_reader :command, :options

    def initialize(command, options = {})
      @command = command
      @options = options
    end

    def execute
      opts = {}
      opts[:chdir] = path if path
      execute_command command, opts unless dry_run?
    end

    private

    def execute_command(cmd, cmd_opts = {})
      loop do
        cmd_options = {}
        if options[:capture]
          read, write = IO.pipe
          cmd_options[[:out, :err]] = write
        end
        puts cmd
        pid = Process.spawn(
          options.fetch(:env, {}),
          cmd,
          cmd_options.merge(cmd_opts)
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

        puts "Error: Command failed with status `#{exitstatus.exitstatus}`"
        exit 1
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
