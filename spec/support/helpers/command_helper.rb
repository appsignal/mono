# frozen_string_literal: true

module CommandHelper
  # Actually run commands executed by the `run_command` helper in the given
  # block.
  def perform_commands(&block)
    Testing.perform_commands(&block)
  end

  # Returns a list of commands that were performed with the `run_command` helper.
  def performed_commands
    Testing.commands
  end

  # When a command is wrapped with {perform_commands} they are actually
  # executed. If you want to make an exception for one or more commands and not
  # execute it, specify them with this block. Prevent accidental `git push` or
  # `gem push` in a test.
  def stub_commands(command_matchers)
    command_matchers.each { |matcher| Testing.stubbed_commands << matcher }
    yield
  end

  def exit_status
    Testing.exit_status || 0
  end

  def run_command(command)
    output = `#{command}`
    exitstatus = $?
    unless exitstatus.success?
      raise <<~ERROR
        Error: Command failed with #{exitstatus.exitstatus}
        Command: #{command}
        Output:\n#{output}
      ERROR
    end

    output
  end
end
