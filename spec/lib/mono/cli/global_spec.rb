# frozen_string_literal: true

RSpec.describe Mono::Cli do
  context "with --version option" do
    it "prints the Mono version number and exits" do
      output =
        capture_stdout do
          expect { run(["--version"]) }.to raise_error(SystemExit) do |error|
            expect(error.status).to eql(0)
          end
        end

      expect(output).to include("Mono #{Mono::VERSION}")
      expect(performed_commands).to eql([])
    end
  end

  context "with --help option" do
    it "prints help and exits" do
      output =
        capture_stdout do
          expect { run(["--help"]) }.to raise_error(SystemExit) do |error|
            expect(error.status).to eql(0)
          end
        end

      expect(output).to include(
        "Usage: mono <command> [options]",
        "Available commands: init, bootstrap"
      )
      expect(performed_commands).to eql([])
    end
  end

  context "with unknown command" do
    it "prints error and exits" do
      output =
        capture_stdout do
          expect { run(["unknown"]) }.to raise_error(SystemExit) do |error|
            expect(error.status).to eql(1)
          end
        end

      expect(output).to include("Unknown command: unknown")
      expect(performed_commands).to eql([])
    end
  end

  context "with a Mono error" do
    it "prints error and exits" do
      prepare_project :unknown_single
      output =
        capture_stdout do
          in_project { run(["run", "false"]) }
        end

      expect(output).to include(
        "A Mono error was encountered during the `mono run` command. Stopping operation.",
        "Mono::UnknownLanguageError: Unknown language configured"
      )
      expect(performed_commands).to eql([])
      expect(exit_status).to eql(1)
    end
  end

  context "with unknown error" do
    it "prints error and exits" do
      prepare_project :empty
      output =
        capture_stdout do
          expect do
            in_project { run(["run", "false"]) }
          end.to raise_error(SystemCallError)
        end

      expect(output).to include(
        "An unexpected error was encountered during the `mono run` command. Stopping operation."
      )
      expect(performed_commands).to eql([])
    end
  end

  def run(args = [])
    Mono::Cli::Wrapper.new(args).execute
  end
end
