# frozen_string_literal: true

module Testing
  class << self
    def clear!
      @commands = nil
    end

    def commands
      @commands ||= []
    end
  end

  module Command
    def execute
      # Store executed commands with their working directory
      # Do not actually execute the commands
      Testing.commands << [
        Dir.pwd.sub(File.join(SPEC_DIR, "support/examples"), ""),
        command
      ]
    end
  end
end

Mono::Command.prepend(Testing::Command)
