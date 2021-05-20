# frozen_string_literal: true

module Testing
  class << self
    attr_accessor :exit_status

    def clear!
      @perform_commands = false
      @stubbed_commands = nil
      @commands = nil
      @exit_status = nil
    end

    def commands
      @commands ||= []
    end

    def track_command(path, command)
      @commands_mutex ||= Mutex.new
      @commands_mutex.synchronize do
        commands << [path, command]
      end
    end

    def perform_commands
      @perform_commands = true
      yield
    ensure
      @perform_commands = false
    end

    def perform_commands?
      @perform_commands
    end

    def stubbed_commands
      @stubbed_commands ||= []
    end
  end

  module Command
    def execute
      paths = [Dir.pwd]
      paths << path if path # Leave out if empty so the path is consistent
      current_dir = File.join(*paths)

      # Store executed commands with their working directory
      # Do not actually execute the commands unless {Testing.perform_commands}
      # is used.
      Testing.track_command \
        current_dir.sub(File.join(SPEC_DIR, "tmp/examples"), ""),
        command

      return unless Testing.perform_commands?
      return if Testing.stubbed_commands.find { |matcher| matcher.match?(command) }

      super
    end
  end
  Mono::Command.prepend(Testing::Command)
end
