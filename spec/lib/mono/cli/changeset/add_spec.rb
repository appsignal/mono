# frozen_string_literal: true

RSpec.describe Mono::Cli::Changeset do
  around do |example|
    with_mock_stdin { example.run }
  end

  context "with single repo" do
    context "without .changeset directory" do
      it "creates the .changeset directory and a changeset file" do
        prepare_project :elixir_single

        add_cli_input "My:; Awes/o\\me (pa).tch"
        add_cli_input "1" # Type: Added
        add_cli_input "3" # Bump: Patch
        add_cli_input "n"
        output =
          capture_stdout do
            in_project { run_changeset_add }
          end

        changeset_path = ".changesets/my---awes-o-me--pa--tch.md"
        expect(output).to include(
          "Summarize the change (for changeset filename):",
          "Changeset file created at ./#{changeset_path}",
          "Do you want to open this file to add more information? (y/N):"
        ), output
        in_project do
          expect(current_package_changeset_files.length).to eql(1)
          contents = File.read(changeset_path)
          expect(contents).to eql(<<~CHANGESET)
            ---
            bump: patch
            type: add
            ---

            My:; Awes/o\\me (pa).tch
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
        add_cli_input "1" # Type: Added
        add_cli_input "2" # Bump: Minor
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
          "Changeset file created at ./#{changeset_path}",
          "Do you want to open this file to add more information? (y/N):"
        ), output
        in_project do
          expect(current_package_changeset_files.length).to eql(1)
          contents = File.read(changeset_path)
          expect(contents).to eql(<<~CHANGESET)
            ---
            bump: minor
            type: add
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
        add_cli_input "unknown" # Type: Unsupported
        add_cli_input "2" # Type: Change
        add_cli_input "3" # Bump: Patch
        add_cli_input "n"
        output =
          capture_stdout do
            in_project { run_changeset_add }
          end

        changeset_path = ".changesets/my-awes-o-me-patch.md"
        expect(output).to include("Unknown type selected. Please select a type.")
        expect(output.scan(/Select change type /).length).to eql(3)
        in_project do
          expect(current_package_changeset_files.length).to eql(1)
          contents = File.read(changeset_path)
          expect(contents).to eql(<<~CHANGESET)
            ---
            bump: patch
            type: change
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
        add_cli_input "1" # Type: Added
        add_cli_input "" # User presses enter without input
        add_cli_input "unknown" # Type: Unsupported
        add_cli_input "3" # Bump: Patch
        add_cli_input "n"
        output =
          capture_stdout do
            in_project { run_changeset_add }
          end

        changeset_path = ".changesets/my-awes-o-me-patch.md"
        expect(output).to include(
          "Unknown bump type ``. Please select a supported bump type."
        )
        expect(output.scan(/Select bump 1-3/).length).to eql(3)
        in_project do
          expect(current_package_changeset_files.length).to eql(1)
          contents = File.read(changeset_path)
          expect(contents).to eql(<<~CHANGESET)
            ---
            bump: patch
            type: add
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
        add_cli_input "1" # Type: Added
        add_cli_input "3" # Bump: Patch
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
        add_cli_input "1" # Type: Added
        add_cli_input "3" # Bump: Patch
        add_cli_input "y"
        output =
          capture_stdout do
            in_project { run_changeset_add }
          end

        changeset_path = ".changesets/my--awes-o-m----patch.md"
        expect(output).to include(
          "Opening ./#{changeset_path} with editor..."
        )
        expect(performed_commands).to eql([
          ["/elixir_single_project", "$EDITOR ./#{changeset_path}"]
        ])
        expect(exit_status).to eql(0), output
      end
    end

    context "with integrations config" do
      it "stores a single integration" do
        prepare_ruby_project("integrations" => ["ruby", "elixir", "python"]) do
          create_ruby_package_files :name => "mygem", :version => "1.2.3"
        end

        add_cli_input "My change"
        add_cli_input "1" # Type: Added
        add_cli_input "3" # Bump: Patch
        add_cli_input "ruby"
        add_cli_input "n"
        output = capture_stdout { in_project { run_changeset_add } }

        changeset_path = ".changesets/my-change.md"
        expect(output).to include(
          "For which integrations is this change? (all, none, ruby, elixir, python): "
        )
        in_project do
          contents = File.read(changeset_path)
          expect(contents).to eql(<<~CHANGESET)
            ---
            bump: patch
            type: add
            integrations: ruby
            ---

            My change
          CHANGESET
        end
        expect(performed_commands).to be_empty
        expect(exit_status).to eql(0), output
      end

      it "stores multiple integrations" do
        prepare_ruby_project("integrations" => ["ruby", "elixir", "python"]) do
          create_ruby_package_files :name => "mygem", :version => "1.2.3"
        end

        add_cli_input "My change"
        add_cli_input "1" # Type: Added
        add_cli_input "3" # Bump: Patch
        add_cli_input "ruby, elixir"
        add_cli_input "n"
        output = capture_stdout { in_project { run_changeset_add } }

        changeset_path = ".changesets/my-change.md"
        expect(output).to include(
          "For which integrations is this change? (all, none, ruby, elixir, python): "
        )
        in_project do
          contents = File.read(changeset_path)
          expect(contents).to eql(<<~CHANGESET)
            ---
            bump: patch
            type: add
            integrations:
            - ruby
            - elixir
            ---

            My change
          CHANGESET
        end
        expect(performed_commands).to be_empty
        expect(exit_status).to eql(0), output
      end

      it "accept 'all' as integrations" do
        prepare_ruby_project("integrations" => ["ruby", "elixir", "python"]) do
          create_ruby_package_files :name => "mygem", :version => "1.2.3"
        end

        add_cli_input "My change"
        add_cli_input "1" # Type: Added
        add_cli_input "3" # Bump: Patch
        add_cli_input "all"
        add_cli_input "n"
        output = capture_stdout { in_project { run_changeset_add } }

        changeset_path = ".changesets/my-change.md"
        expect(output).to include(
          "For which integrations is this change? (all, none, ruby, elixir, python): "
        )
        in_project do
          contents = File.read(changeset_path)
          expect(contents).to eql(<<~CHANGESET)
            ---
            bump: patch
            type: add
            integrations: all
            ---

            My change
          CHANGESET
        end
        expect(performed_commands).to be_empty
        expect(exit_status).to eql(0), output
      end

      it "accept only 'all' as integrations" do
        prepare_ruby_project("integrations" => ["ruby", "elixir", "python"]) do
          create_ruby_package_files :name => "mygem", :version => "1.2.3"
        end

        add_cli_input "My change"
        add_cli_input "1" # Type: Added
        add_cli_input "3" # Bump: Patch
        add_cli_input "ruby, all"
        add_cli_input "n"
        output = capture_stdout { in_project { run_changeset_add } }

        changeset_path = ".changesets/my-change.md"
        expect(output).to include(
          "For which integrations is this change? (all, none, ruby, elixir, python): "
        )
        in_project do
          contents = File.read(changeset_path)
          expect(contents).to eql(<<~CHANGESET)
            ---
            bump: patch
            type: add
            integrations: all
            ---

            My change
          CHANGESET
        end
        expect(performed_commands).to be_empty
        expect(exit_status).to eql(0), output
      end

      it "accept 'none' as integrations" do
        prepare_ruby_project("integrations" => ["ruby", "elixir", "python"]) do
          create_ruby_package_files :name => "mygem", :version => "1.2.3"
        end

        add_cli_input "My change"
        add_cli_input "1" # Type: Added
        add_cli_input "3" # Bump: Patch
        add_cli_input "none"
        add_cli_input "n"
        output = capture_stdout { in_project { run_changeset_add } }

        changeset_path = ".changesets/my-change.md"
        expect(output).to include(
          "For which integrations is this change? (all, none, ruby, elixir, python): "
        )
        in_project do
          contents = File.read(changeset_path)
          expect(contents).to eql(<<~CHANGESET)
            ---
            bump: patch
            type: add
            integrations: none
            ---

            My change
          CHANGESET
        end
        expect(performed_commands).to be_empty
        expect(exit_status).to eql(0), output
      end

      it "accept only 'none' as integrations" do
        prepare_ruby_project("integrations" => ["ruby", "elixir", "python"]) do
          create_ruby_package_files :name => "mygem", :version => "1.2.3"
        end

        add_cli_input "My change"
        add_cli_input "1" # Type: Added
        add_cli_input "3" # Bump: Patch
        add_cli_input "elixir, none"
        add_cli_input "n"
        output = capture_stdout { in_project { run_changeset_add } }

        changeset_path = ".changesets/my-change.md"
        expect(output).to include(
          "For which integrations is this change? (all, none, ruby, elixir, python): "
        )
        in_project do
          contents = File.read(changeset_path)
          expect(contents).to eql(<<~CHANGESET)
            ---
            bump: patch
            type: add
            integrations: none
            ---

            My change
          CHANGESET
        end
        expect(performed_commands).to be_empty
        expect(exit_status).to eql(0), output
      end

      it "does not accept unknown integrations" do
        prepare_ruby_project("integrations" => ["ruby", "elixir", "python"]) do
          create_ruby_package_files :name => "mygem", :version => "1.2.3"
        end

        add_cli_input "My change"
        add_cli_input "1" # Type: Added
        add_cli_input "3" # Bump: Patch
        add_cli_input "" # Empty value
        add_cli_input ",,," # Empty list gets ignored
        add_cli_input "random 1"
        add_cli_input "random 1, , random 2" # Multiple values with empty value
        add_cli_input "python"
        add_cli_input "n"
        output = capture_stdout { in_project { run_changeset_add } }

        changeset_path = ".changesets/my-change.md"
        expect(output).to include(
          "For which integrations is this change? (all, none, ruby, elixir, python): ",
          "Unknown integration entered: \"random 1\". Please try again.",
          "Unknown integration entered: \"random 1\", \"random 2\". Please try again."
        )
        in_project do
          contents = File.read(changeset_path)
          expect(contents).to eql(<<~CHANGESET)
            ---
            bump: patch
            type: add
            integrations: python
            ---

            My change
          CHANGESET
        end
        expect(performed_commands).to be_empty
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
      add_cli_input "1" # Type: Added
      add_cli_input "1" # Change: Major
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
        "What type of semver bump is this?",
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
          bump: major
          type: add
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
