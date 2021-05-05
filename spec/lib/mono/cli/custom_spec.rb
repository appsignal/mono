# frozen_string_literal: true

RSpec.describe Mono::Cli::Custom do
  context "with single repo" do
    it "runs command in root" do
      prepare_project :elixir_single
      output =
        capture_stdout do
          in_project { run_custom ["echo", "123"] }
        end

      expect(output).to include("Custom command for package: elixir_single_project (.)")
      expect(performed_commands).to eql([
        ["/elixir_single_project", "echo 123"]
      ])
      expect(exit_status).to eql(0), output
    end
  end

  context "with mono repo" do
    it "runs command in each package" do
      prepare_project :elixir_mono
      output =
        capture_stdout do
          in_project { run_custom ["echo", "123"] }
        end

      expect(output).to include(
        "Custom command for package: package_one (packages/package_one)",
        "Custom command for package: package_two (packages/package_two)"
      )
      expect(performed_commands).to eql([
        ["/elixir_mono_project/packages/package_one", "echo 123"],
        ["/elixir_mono_project/packages/package_two", "echo 123"]
      ])
      expect(exit_status).to eql(0), output
    end
  end

  def run_custom(args = [])
    Mono::Cli::Wrapper.new(["run"] + args).execute
  end
end
