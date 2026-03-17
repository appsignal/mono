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

      it "strips special symbols from the start and end of the filename" do
        prepare_project :elixir_single

        add_cli_input ":my patch:"
        add_cli_input "1" # Type: Added
        add_cli_input "3" # Bump: Patch
        add_cli_input "n"
        output =
          capture_stdout do
            in_project { run_changeset_add }
          end

        changeset_path = ".changesets/my-patch.md"
        expect(output).to include("Changeset file created at ./#{changeset_path}")
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

      it "does not accept 'all' combined with other integrations" do
        prepare_ruby_project("integrations" => ["ruby", "elixir", "python"]) do
          create_ruby_package_files :name => "mygem", :version => "1.2.3"
        end

        add_cli_input "My change"
        add_cli_input "1" # Type: Added
        add_cli_input "3" # Bump: Patch
        add_cli_input "ruby, all"
        add_cli_input "all"
        add_cli_input "n"
        output = capture_stdout { in_project { run_changeset_add } }

        expect(output).to include(
          "\"all\" cannot be combined with other integrations. Please try again."
        ), output
        expect(exit_status).to eql(0), output
      end

      it "does not accept 'none' combined with other integrations" do
        prepare_ruby_project("integrations" => ["ruby", "elixir", "python"]) do
          create_ruby_package_files :name => "mygem", :version => "1.2.3"
        end

        add_cli_input "My change"
        add_cli_input "1" # Type: Added
        add_cli_input "3" # Bump: Patch
        add_cli_input "elixir, none"
        add_cli_input "none"
        add_cli_input "n"
        output = capture_stdout { in_project { run_changeset_add } }

        expect(output).to include(
          "\"none\" cannot be combined with other integrations. Please try again."
        ), output
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

  context "when non-interactive flags are provided without --message" do
    it "exits with an error listing the offending flags" do
      prepare_project :elixir_single

      output =
        capture_stdout do
          in_project do
            run_changeset_add ["--type", "fix", "--bump", "patch"]
          end
        end

      expect(output).to include(
        "--type, --bump provided without --message.",
        "Non-interactive flags require --message / -m to be set."
      ), output
      expect(exit_status).to eql(1), output
    end

    it "exits with an error for a single offending flag" do
      prepare_project :elixir_single

      output =
        capture_stdout do
          in_project do
            run_changeset_add ["--bump", "patch"]
          end
        end

      expect(output).to include(
        "--bump provided without --message.",
        "Non-interactive flags require --message / -m to be set."
      ), output
      expect(exit_status).to eql(1), output
    end
  end

  context "in non-interactive mode" do
    context "with single repo" do
      it "creates a changeset file without prompts" do
        prepare_project :elixir_single

        output =
          capture_stdout do
            in_project do
              run_changeset_add ["-m", "Fix the thing", "--type", "fix", "--bump", "patch"]
            end
          end

        changeset_path = ".changesets/fix-the-thing.md"
        expect(output).to include("Changeset file created at ./#{changeset_path}")
        expect(output).not_to include("Summarize the change")
        expect(output).not_to include("Do you want to open this file")
        in_project do
          expect(current_package_changeset_files.length).to eql(1)
          contents = File.read(changeset_path)
          expect(contents).to eql(<<~CHANGESET)
            ---
            bump: patch
            type: fix
            ---

            Fix the thing.
          CHANGESET
        end
        expect(performed_commands).to eql([])
        expect(exit_status).to eql(0), output
      end

      it "creates a single-line body joining multiple -m values as sentences" do
        prepare_project :elixir_single

        output =
          capture_stdout do
            in_project do
              run_changeset_add [
                "-m", "Fix the thing",
                "-m", "More detail about the fix.",
                "--type", "fix", "--bump", "patch"
              ]
            end
          end

        changeset_path = ".changesets/fix-the-thing.md"
        expect(output).to include("Changeset file created at ./#{changeset_path}")
        in_project do
          contents = File.read(changeset_path)
          expect(contents).to eql(<<~CHANGESET)
            ---
            bump: patch
            type: fix
            ---

            Fix the thing. More detail about the fix.
          CHANGESET
        end
        expect(exit_status).to eql(0), output
      end

      it "does not double up a period when the -m value already ends with one" do
        prepare_project :elixir_single

        output =
          capture_stdout do
            in_project do
              run_changeset_add [
                "-m", "Fix the thing.",
                "-m", "More detail.",
                "--type", "fix", "--bump", "patch"
              ]
            end
          end

        in_project do
          contents = File.read(".changesets/fix-the-thing.md")
          expect(contents).to include("Fix the thing. More detail.")
        end
        expect(exit_status).to eql(0), output
      end

      it "exits with an error when --type is missing" do
        prepare_project :elixir_single

        output =
          capture_stdout do
            in_project do
              run_changeset_add ["-m", "Fix the thing", "--bump", "patch"]
            end
          end

        expect(output).to include(
          "--type is required in non-interactive mode.",
          "Allowed values: add, change, deprecate, remove, fix, security"
        ), output
        expect(exit_status).to eql(1), output
      end

      it "exits with an error when --bump is missing" do
        prepare_project :elixir_single

        output =
          capture_stdout do
            in_project do
              run_changeset_add ["-m", "Fix the thing", "--type", "fix"]
            end
          end

        expect(output).to include(
          "--bump is required in non-interactive mode.",
          "Allowed values: major, minor, patch"
        ), output
        expect(exit_status).to eql(1), output
      end

      it "exits with an error for an invalid --type value" do
        prepare_project :elixir_single

        output =
          capture_stdout do
            in_project do
              run_changeset_add ["-m", "Fix the thing", "--type", "bogus", "--bump", "patch"]
            end
          end

        expect(output).to include(
          "--type is required in non-interactive mode.",
          "Allowed values: add, change, deprecate, remove, fix, security"
        ), output
        expect(exit_status).to eql(1), output
      end

      it "exits with an error for an invalid --bump value" do
        prepare_project :elixir_single

        output =
          capture_stdout do
            in_project do
              run_changeset_add ["-m", "Fix the thing", "--type", "fix", "--bump", "bogus"]
            end
          end

        expect(output).to include(
          "--bump is required in non-interactive mode.",
          "Allowed values: major, minor, patch"
        ), output
        expect(exit_status).to eql(1), output
      end

      context "with integrations config" do
        it "creates a changeset with a valid integration" do
          prepare_ruby_project("integrations" => ["ruby", "elixir", "python"]) do
            create_ruby_package_files :name => "mygem", :version => "1.2.3"
          end

          output =
            capture_stdout do
              in_project do
                run_changeset_add [
                  "-m", "My change", "--type", "add", "--bump", "patch",
                  "--integration", "ruby"
                ]
              end
            end

          changeset_path = ".changesets/my-change.md"
          expect(output).to include("Changeset file created at ./#{changeset_path}")
          in_project do
            contents = File.read(changeset_path)
            expect(contents).to eql(<<~CHANGESET)
              ---
              bump: patch
              type: add
              integrations: ruby
              ---

              My change.
            CHANGESET
          end
          expect(performed_commands).to be_empty
          expect(exit_status).to eql(0), output
        end

        it "creates a changeset with 'all' integration" do
          prepare_ruby_project("integrations" => ["ruby", "elixir", "python"]) do
            create_ruby_package_files :name => "mygem", :version => "1.2.3"
          end

          output =
            capture_stdout do
              in_project do
                run_changeset_add [
                  "-m", "My change", "--type", "add", "--bump", "patch",
                  "--integration", "all"
                ]
              end
            end

          changeset_path = ".changesets/my-change.md"
          in_project do
            contents = File.read(changeset_path)
            expect(contents).to eql(<<~CHANGESET)
              ---
              bump: patch
              type: add
              integrations: all
              ---

              My change.
            CHANGESET
          end
          expect(exit_status).to eql(0), output
        end

        it "creates a changeset with 'none' integration" do
          prepare_ruby_project("integrations" => ["ruby", "elixir", "python"]) do
            create_ruby_package_files :name => "mygem", :version => "1.2.3"
          end

          output =
            capture_stdout do
              in_project do
                run_changeset_add [
                  "-m", "My change", "--type", "add", "--bump", "patch",
                  "--integration", "none"
                ]
              end
            end

          changeset_path = ".changesets/my-change.md"
          in_project do
            contents = File.read(changeset_path)
            expect(contents).to eql(<<~CHANGESET)
              ---
              bump: patch
              type: add
              integrations: none
              ---

              My change.
            CHANGESET
          end
          expect(exit_status).to eql(0), output
        end

        it "creates a changeset with multiple integrations" do
          prepare_ruby_project("integrations" => ["ruby", "elixir", "python"]) do
            create_ruby_package_files :name => "mygem", :version => "1.2.3"
          end

          output =
            capture_stdout do
              in_project do
                run_changeset_add [
                  "-m", "My change", "--type", "add", "--bump", "patch",
                  "--integration", "ruby,elixir"
                ]
              end
            end

          changeset_path = ".changesets/my-change.md"
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

              My change.
            CHANGESET
          end
          expect(exit_status).to eql(0), output
        end

        it "exits with an error when --integration is missing" do
          prepare_ruby_project("integrations" => ["ruby", "elixir", "python"]) do
            create_ruby_package_files :name => "mygem", :version => "1.2.3"
          end

          output =
            capture_stdout do
              in_project do
                run_changeset_add ["-m", "My change", "--type", "add", "--bump", "patch"]
              end
            end

          expect(output).to include(
            "--integration is required in non-interactive mode",
            "Allowed values: all, none, ruby, elixir, python"
          ), output
          expect(exit_status).to eql(1), output
        end

        it "exits with an error for an unknown integration" do
          prepare_ruby_project("integrations" => ["ruby", "elixir", "python"]) do
            create_ruby_package_files :name => "mygem", :version => "1.2.3"
          end

          output =
            capture_stdout do
              in_project do
                run_changeset_add [
                  "-m", "My change", "--type", "add", "--bump", "patch",
                  "--integration", "unknown"
                ]
              end
            end

          expect(output).to include(
            "Unknown integration(s): \"unknown\".",
            "Allowed values: all, none, ruby, elixir, python"
          ), output
          expect(exit_status).to eql(1), output
        end

        it "exits with an error when 'all' is combined with other integrations" do
          prepare_ruby_project("integrations" => ["ruby", "elixir", "python"]) do
            create_ruby_package_files :name => "mygem", :version => "1.2.3"
          end

          output =
            capture_stdout do
              in_project do
                run_changeset_add [
                  "-m", "My change", "--type", "add", "--bump", "patch",
                  "--integration", "all,ruby"
                ]
              end
            end

          expect(output).to include(
            "\"all\" cannot be combined with other integrations."
          ), output
          expect(exit_status).to eql(1), output
        end

        it "exits with an error when 'none' is combined with other integrations" do
          prepare_ruby_project("integrations" => ["ruby", "elixir", "python"]) do
            create_ruby_package_files :name => "mygem", :version => "1.2.3"
          end

          output =
            capture_stdout do
              in_project do
                run_changeset_add [
                  "-m", "My change", "--type", "add", "--bump", "patch",
                  "--integration", "none,ruby"
                ]
              end
            end

          expect(output).to include(
            "\"none\" cannot be combined with other integrations."
          ), output
          expect(exit_status).to eql(1), output
        end

        it "exits with an error when --integration is used on a project with no integrations" do
          prepare_project :elixir_single

          output =
            capture_stdout do
              in_project do
                run_changeset_add [
                  "-m", "Fix the thing", "--type", "fix", "--bump", "patch",
                  "--integration", "ruby"
                ]
              end
            end

          expect(output).to include(
            "--integration was provided but this project has no integrations configured."
          ), output
          expect(exit_status).to eql(1), output
        end
      end
    end

    context "with mono repo" do
      it "creates a changeset in the specified package" do
        prepare_project :elixir_mono

        output =
          capture_stdout do
            in_project do
              run_changeset_add [
                "-m", "Add feature", "--type", "add", "--bump", "minor",
                "-p", "package_one"
              ]
            end
          end

        changeset_path = "packages/package_one/.changesets/add-feature.md"
        expect(output).to include("Changeset file created at #{changeset_path}")
        expect(output).not_to include("Select package")
        expect(output).not_to include("Do you want to open this file")
        in_project do
          contents = File.read(changeset_path)
          expect(contents).to eql(<<~CHANGESET)
            ---
            bump: minor
            type: add
            ---

            Add feature.
          CHANGESET
        end
        expect(performed_commands).to eql([])
        expect(exit_status).to eql(0), output
      end

      it "exits with an error when --package is missing in a monorepo" do
        prepare_project :elixir_mono

        output =
          capture_stdout do
            in_project do
              run_changeset_add ["-m", "Add feature", "--type", "add", "--bump", "minor"]
            end
          end

        expect(output).to include(
          "--package is required in non-interactive mode for monorepos.",
          "Available packages: package_one, package_two"
        ), output
        expect(exit_status).to eql(1), output
      end

      it "exits with an error naming valid packages when an unknown --package is given" do
        prepare_project :elixir_mono

        output =
          capture_stdout do
            in_project do
              run_changeset_add [
                "-m", "Add feature", "--type", "add", "--bump", "minor",
                "-p", "bogus"
              ]
            end
          end

        expect(output).to include(
          "The package with the name `bogus` could not be found.",
          "Available packages: package_one, package_two"
        ), output
        expect(exit_status).to eql(1), output
      end

      it "exits with an error when --package is used in a single-package project" do
        prepare_project :elixir_single

        output =
          capture_stdout do
            in_project do
              run_changeset_add [
                "-m", "Fix the thing", "--type", "fix", "--bump", "patch",
                "-p", "mypackage"
              ]
            end
          end

        expect(output).to include(
          "--package is not supported for single-package projects."
        ), output
        expect(exit_status).to eql(1), output
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

  context "validate changeset after editing" do
    context "when the file is valid after editing" do
      it "exits successfully without asking to re-edit" do
        prepare_project :elixir_single

        add_cli_input "My patch"
        add_cli_input "1" # Type: Added
        add_cli_input "3" # Bump: Patch
        add_cli_input "y" # Open editor

        output = capture_stdout { in_project { run_changeset_add } }

        expect(output).to include("Opening")
        expect(output).not_to include("Do you want to edit the file again?")
        expect(exit_status).to eql(0), output
      end
    end

    context "when the file is invalid after editing" do
      it "shows errors and exits 1 when user declines to re-edit" do
        prepare_project :elixir_single

        add_cli_input "My patch"
        add_cli_input "1" # Type: Added
        add_cli_input "3" # Bump: Patch
        add_cli_input "y" # Open editor
        add_cli_input "n" # Decline to re-edit

        allow_any_instance_of(Mono::Cli::Changeset::Validate)
          .to receive(:validate_changeset_file)
          .and_return(Mono::Changeset::ParseResult.new(
            "./.changesets/my-patch.md", nil,
            [Mono::Changeset::ValidationIssue::UnknownBump.new("bad"),
             Mono::Changeset::ValidationIssue::UnknownType.new("bad")]
          ))

        output = capture_stdout { in_project { run_changeset_add } }

        expect(output).to eq("#{<<~OUTPUT.chomp} "), output
          Summarize the change (for changeset filename): What type of change is this?
          1: Added
          2: Changed
          3: Deprecated
          4: Removed
          5: Fixed
          6: Security
          Select change type 1-6: What type of semver bump is this?
          1: Major
          2: Minor
          3: Patch
          Select bump 1-3: Changeset file created at ./.changesets/my-patch.md
          Do you want to open this file to add more information? (y/N): Opening ./.changesets/my-patch.md with editor...
          Invalid: ./.changesets/my-patch.md (2 errors)
          - [Error] Unknown `bump` metadata: `bad`
          - [Error] Unknown `type` metadata: `bad`

          Do you want to edit the file again? (y/N):
        OUTPUT
        expect(exit_status).to eql(1), output
      end

      it "prompts to re-edit again when user says yes" do
        prepare_project :elixir_single

        add_cli_input "My patch"
        add_cli_input "1" # Type: Added
        add_cli_input "3" # Bump: Patch
        add_cli_input "y" # Open editor
        add_cli_input "y" # Re-edit
        add_cli_input "n" # Decline after second edit

        allow_any_instance_of(Mono::Cli::Changeset::Validate)
          .to receive(:validate_changeset_file)
          .and_return(Mono::Changeset::ParseResult.new(
            "./.changesets/my-patch.md", nil,
            [Mono::Changeset::ValidationIssue::UnknownBump.new("bad")]
          ))

        output = capture_stdout { in_project { run_changeset_add } }

        expect(output).to eq("#{<<~OUTPUT.chomp} "), output
          Summarize the change (for changeset filename): What type of change is this?
          1: Added
          2: Changed
          3: Deprecated
          4: Removed
          5: Fixed
          6: Security
          Select change type 1-6: What type of semver bump is this?
          1: Major
          2: Minor
          3: Patch
          Select bump 1-3: Changeset file created at ./.changesets/my-patch.md
          Do you want to open this file to add more information? (y/N): Opening ./.changesets/my-patch.md with editor...
          Invalid: ./.changesets/my-patch.md (1 error)
          - [Error] Unknown `bump` metadata: `bad`

          Do you want to edit the file again? (y/N): Opening ./.changesets/my-patch.md with editor...
          Invalid: ./.changesets/my-patch.md (1 error)
          - [Error] Unknown `bump` metadata: `bad`

          Do you want to edit the file again? (y/N):
        OUTPUT
        expect(exit_status).to eql(1), output
      end
    end

    context "when the file has warnings after editing" do
      it "shows warnings but exits 0 when user declines to re-edit" do
        prepare_project :elixir_single

        add_cli_input "My patch"
        add_cli_input "1" # Type: Added
        add_cli_input "3" # Bump: Patch
        add_cli_input "y" # Open editor
        add_cli_input "n" # Decline to re-edit

        allow_any_instance_of(Mono::Cli::Changeset::Validate)
          .to receive(:validate_changeset_file)
          .and_return(Mono::Changeset::ParseResult.new(
            "./.changesets/my-patch.md", double("changeset"),
            [Mono::Changeset::ValidationIssue::UnexpectedIntegrations.new]
          ))

        output = capture_stdout { in_project { run_changeset_add } }

        expect(output).to eq("#{<<~OUTPUT.chomp} "), output
          Summarize the change (for changeset filename): What type of change is this?
          1: Added
          2: Changed
          3: Deprecated
          4: Removed
          5: Fixed
          6: Security
          Select change type 1-6: What type of semver bump is this?
          1: Major
          2: Minor
          3: Patch
          Select bump 1-3: Changeset file created at ./.changesets/my-patch.md
          Do you want to open this file to add more information? (y/N): Opening ./.changesets/my-patch.md with editor...
          Valid: ./.changesets/my-patch.md (1 warning)
          - [Warning] Has `integrations` metadata but project has no integrations configured

          Do you want to edit the file again? (y/N):
        OUTPUT
        expect(exit_status).to eql(0), output
      end
    end
  end

  context "validate output of changeset add" do
    context "with single repo" do
      it "generates a changeset that passes validation" do
        prepare_project :elixir_single

        in_project do
          run_changeset_add ["-m", "Fix the thing", "--type", "fix", "--bump", "patch"]
        end

        output = capture_stdout { in_project { run_changeset_validate } }

        expect(output).to include("All changesets are valid.")
        expect(exit_status).to eql(0), output
      end
    end

    context "with integrations config" do
      it "generates a changeset with integrations that passes validation" do
        prepare_ruby_project("integrations" => ["ruby", "elixir"]) do
          create_ruby_package_files :name => "mygem", :version => "1.2.3"
        end

        in_project do
          run_changeset_add [
            "-m", "My change", "--type", "add", "--bump", "minor",
            "--integration", "ruby"
          ]
        end

        output = capture_stdout { in_project { run_changeset_validate } }

        expect(output).to include("All changesets are valid.")
        expect(exit_status).to eql(0), output
      end
    end

    context "with mono repo" do
      it "generates a changeset in a package that passes validation" do
        prepare_project :elixir_mono

        in_project do
          run_changeset_add [
            "-m", "Add feature", "--type", "add", "--bump", "minor",
            "-p", "package_one"
          ]
        end

        output = capture_stdout { in_project { run_changeset_validate } }

        expect(output).to include("All changesets are valid.")
        expect(exit_status).to eql(0), output
      end
    end
  end

  def run_changeset_add(args = [])
    prepare_cli_input
    Mono::Cli::Wrapper.new(["changeset", "add"] + args).execute
  end

  def run_changeset_validate(args = [])
    Mono::Cli::Wrapper.new(["changeset", "validate"] + args).execute
  end
end
