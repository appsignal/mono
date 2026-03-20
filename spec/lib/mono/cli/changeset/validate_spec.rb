# frozen_string_literal: true

RSpec.describe Mono::Cli::Changeset::Validate do
  context "with single repo" do
    context "without .changesets directory" do
      it "exits 0 and prints all valid" do
        prepare_project :ruby_single

        output =
          capture_stdout do
            in_project { run_changeset_validate }
          end

        expect(output).to eq(<<~OUTPUT)
          Found 0 changesets. All changesets are valid.
        OUTPUT
        expect(exit_status).to eql(0), output
      end
    end

    context "with all valid changesets" do
      it "exits 0 and lists each as valid" do
        prepare_project :ruby_single

        in_project do
          add_changeset :patch, :type => :add, :message => "A patch fix.", :commit => false
          add_changeset :minor, :type => :change, :message => "A minor change.", :commit => false
        end

        output =
          capture_stdout do
            in_project { run_changeset_validate }
          end

        expect(output).to eq(<<~OUTPUT)
          Valid: ./.changesets/1_patch.md

          Valid: ./.changesets/2_minor.md

          Found 2 changesets. All changesets are valid.
        OUTPUT
        expect(exit_status).to eql(0), output
      end
    end

    context "with an invalid changeset (bad bump)" do
      it "exits 1 and reports the error" do
        prepare_project :ruby_single

        in_project do
          FileUtils.mkdir_p(".changesets")
          File.write(".changesets/bad_bump.md", <<~CHANGESET)
            ---
            bump: bogus
            type: add
            ---

            Some change.
          CHANGESET
        end

        output =
          capture_stdout do
            in_project { run_changeset_validate }
          end

        expect(output).to eq(<<~OUTPUT)
          Invalid: ./.changesets/bad_bump.md (1 error)
          - [Error] Unknown `bump` metadata: `bogus`

          Found 1 changeset. 1 changeset is invalid.
        OUTPUT
        expect(exit_status).to eql(1), output
      end
    end

    context "with an invalid changeset (missing bump)" do
      it "exits 1 and reports the error" do
        prepare_project :ruby_single

        in_project do
          FileUtils.mkdir_p(".changesets")
          File.write(".changesets/missing_bump.md", <<~CHANGESET)
            ---
            type: add
            ---

            Some change.
          CHANGESET
        end

        output =
          capture_stdout do
            in_project { run_changeset_validate }
          end

        expect(output).to eq(<<~OUTPUT)
          Invalid: ./.changesets/missing_bump.md (1 error)
          - [Error] Missing `bump` metadata

          Found 1 changeset. 1 changeset is invalid.
        OUTPUT
        expect(exit_status).to eql(1), output
      end
    end

    context "with an invalid changeset (missing type)" do
      it "exits 1 and reports the error" do
        prepare_project :ruby_single

        in_project do
          FileUtils.mkdir_p(".changesets")
          File.write(".changesets/missing_type.md", <<~CHANGESET)
            ---
            bump: patch
            ---

            Some change.
          CHANGESET
        end

        output =
          capture_stdout do
            in_project { run_changeset_validate }
          end

        expect(output).to eq(<<~OUTPUT)
          Invalid: ./.changesets/missing_type.md (1 error)
          - [Error] Missing `type` metadata

          Found 1 changeset. 1 changeset is invalid.
        OUTPUT
        expect(exit_status).to eql(1), output
      end
    end

    context "with an unknown metadata key" do
      it "exits 0 and reports a warning" do
        prepare_project :ruby_single

        in_project do
          FileUtils.mkdir_p(".changesets")
          File.write(".changesets/unknown_key.md", <<~CHANGESET)
            ---
            bump: patch
            type: add
            foo: bar
            ---

            Some change.
          CHANGESET
        end

        output =
          capture_stdout do
            in_project { run_changeset_validate }
          end

        expect(output).to eq(<<~OUTPUT)
          Valid: ./.changesets/unknown_key.md (1 warning)
          - [Warning] Unknown metadata key: `foo`

          Found 1 changeset. All changesets are valid. 1 valid changeset has warnings.
        OUTPUT
        expect(exit_status).to eql(0), output
      end
    end

    context "with an invalid changeset (bad type)" do
      it "exits 1 and reports the error" do
        prepare_project :ruby_single

        in_project do
          FileUtils.mkdir_p(".changesets")
          File.write(".changesets/bad_type.md", <<~CHANGESET)
            ---
            bump: patch
            type: bogus
            ---

            Some change.
          CHANGESET
        end

        output =
          capture_stdout do
            in_project { run_changeset_validate }
          end

        expect(output).to eq(<<~OUTPUT)
          Invalid: ./.changesets/bad_type.md (1 error)
          - [Error] Unknown `type` metadata: `bogus`

          Found 1 changeset. 1 changeset is invalid.
        OUTPUT
        expect(exit_status).to eql(1), output
      end
    end

    context "with an invalid changeset (bad bump and bad type)" do
      it "exits 1 and reports both errors" do
        prepare_project :ruby_single

        in_project do
          FileUtils.mkdir_p(".changesets")
          File.write(".changesets/bad_bump_and_type.md", <<~CHANGESET)
            ---
            bump: bogus
            type: bogus
            ---

            Some change.
          CHANGESET
        end

        output =
          capture_stdout do
            in_project { run_changeset_validate }
          end

        expect(output).to eq(<<~OUTPUT)
          Invalid: ./.changesets/bad_bump_and_type.md (2 errors)
          - [Error] Unknown `bump` metadata: `bogus`
          - [Error] Unknown `type` metadata: `bogus`

          Found 1 changeset. 1 changeset is invalid.
        OUTPUT
        expect(exit_status).to eql(1), output
      end
    end

    context "with an invalid changeset (empty message)" do
      it "exits 1 and reports the error" do
        prepare_project :ruby_single

        in_project do
          FileUtils.mkdir_p(".changesets")
          File.write(".changesets/empty_message.md", <<~CHANGESET)
            ---
            bump: patch
            type: add
            ---

          CHANGESET
        end

        output =
          capture_stdout do
            in_project { run_changeset_validate }
          end

        expect(output).to eq(<<~OUTPUT)
          Invalid: ./.changesets/empty_message.md (1 error)
          - [Error] No changeset message found. Please add a description of the change.

          Found 1 changeset. 1 changeset is invalid.
        OUTPUT
        expect(exit_status).to eql(1), output
      end
    end

    context "with a mix of valid and invalid changesets" do
      it "exits 1 and reports the count" do
        prepare_project :ruby_single

        in_project do
          add_changeset :patch, :type => :add, :message => "A valid fix.", :commit => false
          FileUtils.mkdir_p(".changesets")
          File.write(".changesets/bad.md", <<~CHANGESET)
            ---
            bump: bogus
            type: add
            ---

            An invalid changeset.
          CHANGESET
        end

        output =
          capture_stdout do
            in_project { run_changeset_validate }
          end

        expect(output).to eq(<<~OUTPUT)
          Valid: ./.changesets/1_patch.md

          Invalid: ./.changesets/bad.md (1 error)
          - [Error] Unknown `bump` metadata: `bogus`

          Found 2 changesets. 1 changeset is invalid.
        OUTPUT
        expect(exit_status).to eql(1), output
      end
    end

    context "with a mix of invalid and warned changesets" do
      it "exits 1 and reports both counts" do
        prepare_project :ruby_single

        in_project do
          FileUtils.mkdir_p(".changesets")
          File.write(".changesets/bad.md", <<~CHANGESET)
            ---
            bump: bogus
            type: add
            ---

            An invalid changeset.
          CHANGESET
          File.write(".changesets/warned.md", <<~CHANGESET)
            ---
            bump: patch
            type: add
            foo: bar
            ---

            A warned changeset.
          CHANGESET
        end

        output =
          capture_stdout do
            in_project { run_changeset_validate }
          end

        expect(output).to eq(<<~OUTPUT)
          Invalid: ./.changesets/bad.md (1 error)
          - [Error] Unknown `bump` metadata: `bogus`

          Valid: ./.changesets/warned.md (1 warning)
          - [Warning] Unknown metadata key: `foo`

          Found 2 changesets. 1 changeset is invalid. 1 valid changeset has warnings.
        OUTPUT
        expect(exit_status).to eql(1), output
      end
    end
  end

  context "with monorepo" do
    context "with valid changesets across packages" do
      it "exits 0 and lists each as valid" do
        prepare_project :ruby_mono

        in_project do
          in_package :package_one do
            add_changeset :patch, :type => :fix, :message => "Package one fix.", :commit => false
          end
          in_package :package_two do
            add_changeset :minor, :type => :add, :message => "Package two addition.",
              :commit => false
          end
        end

        output =
          capture_stdout do
            in_project { run_changeset_validate }
          end

        expect(output).to eq(<<~OUTPUT)
          Valid: packages/package_one/.changesets/1_patch.md

          Valid: packages/package_two/.changesets/2_minor.md

          Found 2 changesets. All changesets are valid.
        OUTPUT
        expect(exit_status).to eql(0), output
      end
    end

    context "with an invalid changeset in one package" do
      it "exits 1 and reports only the invalid one" do
        prepare_project :ruby_mono

        in_project do
          in_package :package_one do
            add_changeset :patch, :type => :fix, :message => "Valid fix.", :commit => false
          end
          in_package :package_two do
            FileUtils.mkdir_p(".changesets")
            File.write(".changesets/bad.md", <<~CHANGESET)
              ---
              bump: bogus
              type: add
              ---

              An invalid changeset.
            CHANGESET
          end
        end

        output =
          capture_stdout do
            in_project { run_changeset_validate }
          end

        expect(output).to eq(<<~OUTPUT)
          Valid: packages/package_one/.changesets/1_patch.md

          Invalid: packages/package_two/.changesets/bad.md (1 error)
          - [Error] Unknown `bump` metadata: `bogus`

          Found 2 changesets. 1 changeset is invalid.
        OUTPUT
        expect(exit_status).to eql(1), output
      end
    end
  end

  context "with integrations config" do
    context "with missing integrations metadata" do
      it "exits 1" do
        prepare_ruby_project("integrations" => ["ruby", "elixir"]) do
          create_ruby_package_files :name => "mygem", :version => "1.2.3"
        end

        in_project do
          FileUtils.mkdir_p(".changesets")
          File.write(".changesets/missing_integration.md", <<~CHANGESET)
            ---
            bump: patch
            type: add
            ---

            A change.
          CHANGESET
        end

        output = capture_stdout { in_project { run_changeset_validate } }

        expect(output).to eq(<<~OUTPUT)
          Invalid: ./.changesets/missing_integration.md (1 error)
          - [Error] Missing `integrations` metadata. Allowed values: all, none, ruby, elixir

          Found 1 changeset. 1 changeset is invalid.
        OUTPUT
        expect(exit_status).to eql(1), output
      end
    end

    context "with a valid single integration" do
      it "exits 0" do
        prepare_ruby_project("integrations" => ["ruby", "elixir"]) do
          create_ruby_package_files :name => "mygem", :version => "1.2.3"
        end

        in_project do
          FileUtils.mkdir_p(".changesets")
          File.write(".changesets/valid.md", <<~CHANGESET)
            ---
            bump: patch
            type: add
            integrations: ruby
            ---

            A change.
          CHANGESET
        end

        output = capture_stdout { in_project { run_changeset_validate } }

        expect(output).to eq(<<~OUTPUT)
          Valid: ./.changesets/valid.md

          Found 1 changeset. All changesets are valid.
        OUTPUT
        expect(exit_status).to eql(0), output
      end
    end

    context "with valid 'all' integration" do
      it "exits 0" do
        prepare_ruby_project("integrations" => ["ruby", "elixir"]) do
          create_ruby_package_files :name => "mygem", :version => "1.2.3"
        end

        in_project do
          FileUtils.mkdir_p(".changesets")
          File.write(".changesets/valid.md", <<~CHANGESET)
            ---
            bump: patch
            type: add
            integrations: all
            ---

            A change.
          CHANGESET
        end

        output = capture_stdout { in_project { run_changeset_validate } }

        expect(output).to eq(<<~OUTPUT)
          Valid: ./.changesets/valid.md

          Found 1 changeset. All changesets are valid.
        OUTPUT
        expect(exit_status).to eql(0), output
      end
    end

    context "with an unknown integration" do
      it "exits 1 and reports the unknown integration" do
        prepare_ruby_project("integrations" => ["ruby", "elixir"]) do
          create_ruby_package_files :name => "mygem", :version => "1.2.3"
        end

        in_project do
          FileUtils.mkdir_p(".changesets")
          File.write(".changesets/bad_integration.md", <<~CHANGESET)
            ---
            bump: patch
            type: add
            integrations: python
            ---

            A change.
          CHANGESET
        end

        output = capture_stdout { in_project { run_changeset_validate } }

        expect(output).to eq(<<~OUTPUT)
          Invalid: ./.changesets/bad_integration.md (1 error)
          - [Error] Unknown integration(s): "python". Allowed values: all, none, ruby, elixir

          Found 1 changeset. 1 changeset is invalid.
        OUTPUT
        expect(exit_status).to eql(1), output
      end
    end

    context "with 'all' combined with other integrations" do
      it "exits 1" do
        prepare_ruby_project("integrations" => ["ruby", "elixir"]) do
          create_ruby_package_files :name => "mygem", :version => "1.2.3"
        end

        in_project do
          FileUtils.mkdir_p(".changesets")
          File.write(".changesets/bad_all.md", <<~CHANGESET)
            ---
            bump: patch
            type: add
            integrations:
            - all
            - ruby
            ---

            A change.
          CHANGESET
        end

        output = capture_stdout { in_project { run_changeset_validate } }

        expect(output).to eq(<<~OUTPUT)
          Invalid: ./.changesets/bad_all.md (1 error)
          - [Error] "all" cannot be combined with other integrations

          Found 1 changeset. 1 changeset is invalid.
        OUTPUT
        expect(exit_status).to eql(1), output
      end
    end

    context "with 'none' combined with other integrations" do
      it "exits 1" do
        prepare_ruby_project("integrations" => ["ruby", "elixir"]) do
          create_ruby_package_files :name => "mygem", :version => "1.2.3"
        end

        in_project do
          FileUtils.mkdir_p(".changesets")
          File.write(".changesets/bad_none.md", <<~CHANGESET)
            ---
            bump: patch
            type: add
            integrations:
            - none
            - ruby
            ---

            A change.
          CHANGESET
        end

        output = capture_stdout { in_project { run_changeset_validate } }

        expect(output).to eq(<<~OUTPUT)
          Invalid: ./.changesets/bad_none.md (1 error)
          - [Error] "none" cannot be combined with other integrations

          Found 1 changeset. 1 changeset is invalid.
        OUTPUT
        expect(exit_status).to eql(1), output
      end
    end

    context "with integrations metadata but no integrations config" do
      it "exits 0 and prints a warning" do
        prepare_ruby_project do
          create_ruby_package_files :name => "mygem", :version => "1.2.3"
        end

        in_project do
          FileUtils.mkdir_p(".changesets")
          File.write(".changesets/with_integration.md", <<~CHANGESET)
            ---
            bump: patch
            type: add
            integrations: ruby
            ---

            A change.
          CHANGESET
        end

        output = capture_stdout { in_project { run_changeset_validate } }

        expect(output).to eq(<<~OUTPUT)
          Valid: ./.changesets/with_integration.md (1 warning)
          - [Warning] Has `integrations` metadata but project has no integrations configured

          Found 1 changeset. All changesets are valid. 1 valid changeset has warnings.
        OUTPUT
        expect(exit_status).to eql(0), output
      end

      context "with --warnings-as-errors flag" do
        it "exits 1" do
          prepare_ruby_project do
            create_ruby_package_files :name => "mygem", :version => "1.2.3"
          end

          in_project do
            FileUtils.mkdir_p(".changesets")
            File.write(".changesets/with_integration.md", <<~CHANGESET)
              ---
              bump: patch
              type: add
              integrations: ruby
              ---

              A change.
            CHANGESET
          end

          output = capture_stdout { in_project { run_changeset_validate(["-w"]) } }

          expect(output).to eq(<<~OUTPUT)
            Invalid: ./.changesets/with_integration.md (1 warning)
            - [Warning] Has `integrations` metadata but project has no integrations configured

            Found 1 changeset. 1 changeset is invalid.
          OUTPUT
          expect(exit_status).to eql(1), output
        end
      end
    end
  end

  context "with -p flag" do
    context "with a selected package" do
      it "only validates the selected package" do
        prepare_project :ruby_mono

        in_project do
          in_package :package_one do
            add_changeset :patch, :type => :fix, :message => "Valid fix.", :commit => false
          end
          in_package :package_two do
            FileUtils.mkdir_p(".changesets")
            File.write(".changesets/bad.md", <<~CHANGESET)
              ---
              bump: bogus
              type: add
              ---

              An invalid changeset.
            CHANGESET
          end
        end

        output =
          capture_stdout do
            in_project { run_changeset_validate(["--package", "package_one"]) }
          end

        expect(output).to eq(<<~OUTPUT)
          Valid: packages/package_one/.changesets/1_patch.md

          Found 1 changeset. All changesets are valid.
        OUTPUT
        expect(exit_status).to eql(0), output
      end
    end

    context "with an unknown package selected" do
      it "exits with an error" do
        prepare_project :ruby_mono

        output =
          capture_stdout do
            in_project { run_changeset_validate(["--package", "package_unknown"]) }
          end

        expect(output).to include("PackageNotFound", "package_unknown"), output
        expect(exit_status).to eql(1), output
      end
    end
  end

  def run_changeset_validate(args = [])
    Mono::Cli::Wrapper.new(["changeset", "validate"] + args).execute
  end
end
