# frozen_string_literal: true

module CliHelper
  def with_mock_stdin
    original_stdin = $stdin
    $stdin = StringIO.new
    yield
  ensure
    $stdin = original_stdin
  end

  def add_cli_input(value)
    $stdin.puts value
  end

  def prepare_cli_input
    # Prepare the input by rewinding the pointer in the StringIO
    $stdin.rewind
  end
end
