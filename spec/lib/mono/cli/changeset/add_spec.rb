# frozen_string_literal: true

RSpec.describe Mono::Cli::Changeset do
  around do |example|
    with_mock_stdin { example.run }
  end

  context "with single repo" do
    context "without .changeset directory" do
      it "creates the .changeset directory and a changeset file" do
        prepare_project :elixir_single

        add_cli_input "My Awes/o\\me patch"
        add_cli_input "patch"
        add_cli_input "n"
        output =
          capture_stdout do
            in_project { run_changeset_add }
          end

        changeset_path = ".changesets/my-awes-o-me-patch.md"
        expect(output).to include(
          "Summarize the change (for changeset filename):",
          "What type of semver bump is this (major/minor/patch): ",
          "Changeset file created at ./#{changeset_path}",
          "Do you want to open this file to add more information? (y/N):"
        ), output
        in_project do
          expect(current_package_changeset_files.length).to eql(1)
          contents = File.read(changeset_path)
          expect(contents).to eql(<<~CHANGESET)
            ---
            bump: "patch"
            ---

            My Awes/o\\me patch
          CHANGESET
        end
        expect(performed_commands).to eql([])
        expect(exit_status).to eql(0), output
      end
    end

    context "without .changeset directory" do
      it "creates the .changeset directory and a changeset file" do
        prepare_project :elixir_single

        add_cli_input "My Awes/o\\me patch"
        add_cli_input "minor"
        add_cli_input "n"
        output =
          capture_stdout do
            in_project do
              FileUtils.mkdir_p(".changsets")
              run_changeset_add
            end
          end

        changeset_path = ".changesets/my-awes-o-me-patch.md"
        expect(output).to include(
          "Summarize the change (for changeset filename):",
          "What type of semver bump is this (major/minor/patch): ",
          "Changeset file created at ./#{changeset_path}",
          "Do you want to open this file to add more information? (y/N):"
        ), output
        in_project do
          expect(current_package_changeset_files.length).to eql(1)
          contents = File.read(changeset_path)
          expect(contents).to eql(<<~CHANGESET)
            ---
            bump: "minor"
            ---

            My Awes/o\\me patch
          CHANGESET
        end
        expect(performed_commands).to eql([])
        expect(exit_status).to eql(0), output
      end
    end
  end

  context "with mono repo" do
    it "creates the changeset file in the selected package" do
      prepare_project :elixir_mono

      add_cli_input "1" # First package
      add_cli_input "My Awes/o\\me patch"
      add_cli_input "major"
      add_cli_input "n"
      output =
        capture_stdout do
          in_project { run_changeset_add }
        end

      changeset_path = "packages/package_one/.changesets/my-awes-o-me-patch.md"
      expect(output).to include(
        "1: package_one (packages/package_one)",
        "2: package_two (packages/package_two)",
        "Summarize the change (for changeset filename):",
        "What type of semver bump is this (major/minor/patch): ",
        "Changeset file created at #{changeset_path}",
        "Do you want to open this file to add more information? (y/N):"
      ), output
      in_project do
        in_package :package_one do
          expect(current_package_changeset_files.length).to eql(1)
        end
        contents = File.read(changeset_path)
        expect(contents).to eql(<<~CHANGESET)
          ---
          bump: "major"
          ---

          My Awes/o\\me patch
        CHANGESET
      end
      expect(performed_commands).to eql([])
      expect(exit_status).to eql(0), output
    end
  end

  def run_changeset_add(args = [])
    prepare_cli_input
    Mono::Cli::Wrapper.new(["changeset", "add"] + args).execute
  end
end
