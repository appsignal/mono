# frozen_string_literal: true

RSpec.describe Mono::Cli::Bootstrap do
  context "with --version option" do
    it "prints the Mono version number and exits" do
      output =
        capture_stdout do
          expect do
            run_command(["--version"])
          end.to raise_error(SystemExit)
        end

      expect(output).to include("Mono #{Mono::VERSION}")
      expect(performed_commands).to eql([])
      expect(exit_status).to eql(0), output
    end
  end

  context "with --help option" do
    it "prints help and exits" do
      output =
        capture_stdout do
          expect do
            run_command(["--help"])
          end.to raise_error(SystemExit)
        end

      expect(output).to include(
        "Usage: mono <command> [options]",
        "Available commands: init, bootstrap"
      )
      expect(performed_commands).to eql([])
      expect(exit_status).to eql(0), output
    end
  end

  def run_command(args = [])
    Mono::Cli::Wrapper.new(args).execute
  end
end
