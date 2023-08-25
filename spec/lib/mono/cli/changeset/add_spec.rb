# frozen_string_literal: true

RSpec.describe Mono::Cli::Changeset do
  around do |example|
    with_mock_stdin { example.run }
  end

  context "with single repo" do
    context "without .changeset directory" do
      it "creates the .changeset directory and a changeset file" do
        prepare_project :elixir_single

        add_cli_input "My:; Awes/o\\me pa.tch"
        add_cli_input "1"
        add_cli_input "patch"
        add_cli_input "n"
        output =
          capture_stdout do
            in_project { run_changeset_add }
          end

        changeset_path = ".changesets/my---awes-o-me-pa-tch.md"
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
            type: "add"
            ---

            My:; Awes/o\\me pa.tch
          CHANGESET
        end
        expect(performed_commands).to eql([])
        expect(exit_status).to eql(0), output
      end
    end

    context "without .changeset directory" do
      it "creates the .changeset directory and a changeset file" do
        prepare_project :elixir_single

        add_cli_input "My Awes/o\\me pa.t`ch"
        add_cli_input "1" # Type: "add"
        add_cli_input "minor"
        add_cli_input "n"
        output =
          capture_stdout do
            in_project do
              FileUtils.mkdir_p(".changsets")
              run_changeset_add
            end
          end

        changeset_path = ".changesets/my-awes-o-me-pa-t-ch.md"
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
            type: "add"
            ---

            My Awes/o\\me pa.t`ch
          CHANGESET
        end
        expect(performed_commands).to eql([])
        expect(exit_status).to eql(0), output
      end
    end

    context "with unknown type" do
      it "repeats the type prompt" do
        prepare_project :elixir_single

        add_cli_input "My Awes/o\\me patch"
        add_cli_input "" # User presses enter without input
        add_cli_input "unknown" # Unsupported type
        add_cli_input "2" # Type: "change"
        add_cli_input "patch" # Supported bump type
        add_cli_input "n"
        output =
          capture_stdout do
            in_project { run_changeset_add }
          end

        changeset_path = ".changesets/my-awes-o-me-patch.md"
        expect(output).to include("Unknown type selected. Please select a type.")
        expect(output.scan(/Select type /).length).to eql(3)
        in_project do
          expect(current_package_changeset_files.length).to eql(1)
          contents = File.read(changeset_path)
          expect(contents).to eql(<<~CHANGESET)
            ---
            bump: "patch"
            type: "change"
            ---

            My Awes/o\\me patch
          CHANGESET
        end
        expect(performed_commands).to eql([])
        expect(exit_status).to eql(0), output
      end
    end

    context "with unknown bump type" do
      it "repeats the bump prompt" do
        prepare_project :elixir_single

        add_cli_input "My Awes/o\\me patch"
        add_cli_input "1" # Type: "add"
        add_cli_input "" # User presses enter without input
        add_cli_input "unknown" # Unsupported bump type
        add_cli_input "patch" # Supported bump type
        add_cli_input "n"
        output =
          capture_stdout do
            in_project { run_changeset_add }
          end

        changeset_path = ".changesets/my-awes-o-me-patch.md"
        expect(output).to include(
          "Unknown bump type `unknown`. Please specify supported bump type."
        )
        expect(output.scan(/What type of semver bump is this/).length).to eql(3)
        in_project do
          expect(current_package_changeset_files.length).to eql(1)
          contents = File.read(changeset_path)
          expect(contents).to eql(<<~CHANGESET)
            ---
            bump: "patch"
            type: "add"
            ---

            My Awes/o\\me patch
          CHANGESET
        end
        expect(performed_commands).to eql([])
        expect(exit_status).to eql(0), output
      end
    end

    context "when opening the file in an editor" do
      it "opens the editor" do
        prepare_project :elixir_single

        add_cli_input "My Awes/o\\me patch"
        add_cli_input "1" # Type: "add"
        add_cli_input "patch"
        add_cli_input "y"
        output =
          capture_stdout do
            in_project { run_changeset_add }
          end

        changeset_path = ".changesets/my-awes-o-me-patch.md"
        expect(output).to include(
          "Opening ./#{changeset_path} with editor..."
        )
        expect(performed_commands).to eql([
          ["/elixir_single_project", "$EDITOR ./#{changeset_path}"]
        ])
        expect(exit_status).to eql(0), output
      end
    end

    context "with special symbols in the description" do
      it "creates a file with a sanitized filename" do
        prepare_project :elixir_single

        add_cli_input "My \"Awes/o\\mé', patch"
        add_cli_input "1" # Type: "add"
        add_cli_input "patch"
        add_cli_input "y"
        output =
          capture_stdout do
            in_project { run_changeset_add }
          end

        changeset_path = ".changesets/my--awes-o-mé---patch.md"
        expect(output).to include(
          "Opening ./#{changeset_path} with editor..."
        )
        expect(performed_commands).to eql([
          ["/elixir_single_project", "$EDITOR ./#{changeset_path}"]
        ])
        expect(exit_status).to eql(0), output
      end
    end
  end

  context "with mono repo" do
    it "creates the changeset file in the selected package" do
      prepare_project :elixir_mono

      add_cli_input "" # User presses enter without input
      add_cli_input "x" # Invalid value
      add_cli_input "0" # Invalid index, no zero package
      add_cli_input "3" # Invalid index, only 2 packages
      add_cli_input "1" # First package
      add_cli_input "My Awes/o\\me patch"
      add_cli_input "1" # Type: "add"
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
      expect(output.scan(/Select package 1-2/).length).to eql(5)
      in_project do
        in_package :package_one do
          expect(current_package_changeset_files.length).to eql(1)
        end
        contents = File.read(changeset_path)
        expect(contents).to eql(<<~CHANGESET)
          ---
          bump: "major"
          type: "add"
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
