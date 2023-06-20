# frozen_string_literal: true

RSpec.describe Mono::Cli::Publish do
  include PublishHelper

  around { |example| with_mock_stdin { example.run } }

  context "with single Elixir package" do
    it "publishes the package" do
      prepare_elixir_project do
        create_package_mix :version => "1.2.3"
      end
      confirm_publish_package
      output = run_publish_process

      project_dir = "/#{current_project}"
      next_version = "1.2.4"

      expect(output).to include(<<~OUTPUT), output
        The following packages will be published (or not):
        - #{current_project}:
          Current version: v1.2.3
          Next version:    v1.2.4 (patch)
      OUTPUT
      expect(output).to include(<<~OUTPUT), output
        # Updating package versions
        - #{current_project}:
          Current version: v1.2.3
          Next version:    v1.2.4 (patch)
      OUTPUT

      in_project do
        expect(File.read("mix.exs")).to include(%(version: "#{next_version}",))
        expect(current_package_changeset_files.length).to eql(0)

        changelog = File.read("CHANGELOG.md")
        expect_changelog_to_include_version_header(changelog, next_version)
        expect_changelog_to_include_release_notes(changelog, :patch)

        expect(local_changes?).to be_falsy, local_changes.inspect
        expect(commited_files).to eql([
          ".changesets/1_patch.md",
          "CHANGELOG.md",
          "mix.exs"
        ])
      end

      expect(performed_commands).to eql([
        [project_dir, "mix deps.get"],
        [project_dir, "git tag --list v#{next_version}"],
        [project_dir, "mix compile"],
        [project_dir, "git add -A"],
        [
          project_dir,
          "git commit -m 'Publish package v#{next_version}' " \
            "-m 'Update version number and CHANGELOG.md.'"
        ],
        [project_dir, "git tag v#{next_version}"],
        [project_dir, "mix hex.publish package --yes"],
        [project_dir, "git push origin main v#{next_version}"]
      ])
      expect(exit_status).to eql(0), output
    end
  end

  context "with single Elixir package that has the version number set in a module attribute" do
    it "publishes the package" do
      prepare_elixir_project do
        create_package_mix :version => "1.2.3", :version_in_module_attribute? => true
      end
      confirm_publish_package
      output = run_publish_process

      project_dir = "/#{current_project}"
      next_version = "1.2.4"

      expect(output).to include(<<~OUTPUT), output
        The following packages will be published (or not):
        - #{current_project}:
          Current version: v1.2.3
          Next version:    v1.2.4 (patch)
      OUTPUT
      expect(output).to include(<<~OUTPUT), output
        # Updating package versions
        - #{current_project}:
          Current version: v1.2.3
          Next version:    v1.2.4 (patch)
      OUTPUT

      in_project do
        contents = File.read("mix.exs")
        expect(contents).to include(%(@version "#{next_version}"))
        expect(contents).to include(%(version: @version,))
        expect(current_package_changeset_files.length).to eql(0)

        changelog = File.read("CHANGELOG.md")
        expect_changelog_to_include_version_header(changelog, next_version)
        expect_changelog_to_include_release_notes(changelog, :patch)

        expect(local_changes?).to be_falsy, local_changes.inspect
        expect(commited_files).to eql([
          ".changesets/1_patch.md",
          "CHANGELOG.md",
          "mix.exs"
        ])
      end

      expect(performed_commands).to eql([
        [project_dir, "mix deps.get"],
        [project_dir, "git tag --list v#{next_version}"],
        [project_dir, "mix compile"],
        [project_dir, "git add -A"],
        [
          project_dir,
          "git commit -m 'Publish package v#{next_version}' " \
            "-m 'Update version number and CHANGELOG.md.'"
        ],
        [project_dir, "git tag v#{next_version}"],
        [project_dir, "mix hex.publish package --yes"],
        [project_dir, "git push origin main v#{next_version}"]
      ])
      expect(exit_status).to eql(0), output
    end

    context "with failing publish command" do
      it "retries to publish" do
        fail_command = "exit 1"
        prepare_elixir_project do
          create_package_mix :version => "1.2.3"
          add_changeset :patch
        end
        confirm_publish_package
        add_cli_input "y" # Retry command
        add_cli_input "n" # Don't retry command
        add_cli_input "n" # Don't rollback changes
        output = run_publish_process(
          :stubbed_commands => [/^git push/],
          :failed_commands => [/^mix hex.publish package --yes/]
        )

        project_dir = "/#{current_project}"
        next_version = "1.2.4"

        expect(output).to include(<<~OUTPUT), output
          #{fail_command}
          Error: Command failed. Do you want to retry? (Y/n): #{fail_command}
          Error: Command failed. Do you want to retry? (Y/n):#{" "}
          A Mono error was encountered during the `mono publish` command. Stopping operation.

          Mono::Error: Command failed with status `1`
        OUTPUT

        expect(performed_commands).to eql([
          [project_dir, "mix deps.get"],
          [project_dir, "git tag --list v#{next_version}"],
          [project_dir, "mix compile"],
          [project_dir, "git add -A"],
          [
            project_dir,
            "git commit -m 'Publish package v#{next_version}' " \
              "-m 'Update version number and CHANGELOG.md.'"
          ],
          [project_dir, "git tag v#{next_version}"],
          [project_dir, "mix hex.publish package --yes"]
        ])
        expect(exit_status).to eql(1), output
      end

      it "rolls back changes" do
        fail_command = "exit 1"
        prepare_elixir_project do
          create_package_mix :version => "1.2.3"
          add_changeset :patch
        end
        confirm_publish_package
        add_cli_input "n" # Don't retry command
        add_cli_input "y" # Rollback changes
        output = run_publish_process(
          :stubbed_commands => [
            /^git push/,
            # Happens after `## Untag package v1.2.4` in output,
            # stubbed because output contains commit hash
            /^git tag -d/
          ],
          :failed_commands => [/^mix hex.publish package --yes/]
        )

        project_dir = "/#{current_project}"
        next_version = "1.2.4"

        expect(output).to include(<<~OUTPUT), output
          #{fail_command}
          Error: Command failed. Do you want to retry? (Y/n):#{" "}
          A Mono error was encountered during the `mono publish` command. Stopping operation.

          Mono::Error: Command failed with status `1`

          Do you want to rollback the above changes? (Y/n)#{" "}
          # Rolling back changes
          ## Untag package v1.2.4
          ## Removing release commit
          git reset --soft HEAD^
          git restore --staged :/
          ## Restoring changelogs
          git restore :/
          ## Restoring package versions
        OUTPUT

        expect(performed_commands).to eql([
          [project_dir, "mix deps.get"],
          [project_dir, "git tag --list v#{next_version}"],
          [project_dir, "mix compile"],
          [project_dir, "git add -A"],
          [
            project_dir,
            "git commit -m 'Publish package v#{next_version}' " \
              "-m 'Update version number and CHANGELOG.md.'"
          ],
          [project_dir, "git tag v#{next_version}"],
          [project_dir, "mix hex.publish package --yes"],
          [project_dir, "git tag -d v1.2.4"],
          [project_dir, "git reset --soft HEAD^"],
          [project_dir, "git restore --staged :/"],
          [project_dir, "git restore :/"]
        ])
        expect(exit_status).to eql(1), output
      end
    end
  end

  context "with mono Elixir project" do
    it "publishes the package" do
      prepare_elixir_project "packages_dir" => "packages/" do
        create_package :package_a do
          create_package_mix :version => "1.2.3"
          add_changeset :patch
        end
        create_package :package_b do
          create_package_mix :version => "2.0.0"
        end
      end
      confirm_publish_package
      output = run_publish_process

      project_dir = "/#{current_project}"
      package_dir_a = "#{project_dir}/packages/package_a"
      package_dir_b = "#{project_dir}/packages/package_b"
      next_version_a = "1.2.4"
      tag = "package_a@#{next_version_a}"

      expect(output).to include(<<~OUTPUT), output
        The following packages will be published (or not):
        - package_a:
          Current version: package_a@1.2.3
          Next version:    package_a@1.2.4 (patch)
        - package_b: (Will not publish)
      OUTPUT
      expect(output).to include(<<~OUTPUT), output
        # Updating package versions
        - package_a:
          Current version: package_a@1.2.3
          Next version:    package_a@1.2.4 (patch)
      OUTPUT

      in_project do
        in_package :package_a do
          expect(File.read("mix.exs")).to include(%(version: "#{next_version_a}",))
          expect(current_package_changeset_files.length).to eql(0)

          changelog = File.read("CHANGELOG.md")
          expect_changelog_to_include_version_header(changelog, next_version_a)
          expect_changelog_to_include_release_notes(changelog, :patch)
        end

        expect(local_changes?).to be_falsy, local_changes.inspect
        expect(commited_files).to eql([
          "packages/package_a/.changesets/1_patch.md",
          "packages/package_a/CHANGELOG.md",
          "packages/package_a/mix.exs"
        ])
      end

      expect(performed_commands).to eql([
        [package_dir_a, "mix deps.get"],
        [package_dir_b, "mix deps.get"],
        [project_dir, "git tag --list #{tag}"],
        [package_dir_a, "mix compile"],
        [project_dir, "git add -A"],
        [
          project_dir,
          "git commit -m 'Publish package #{tag}' " \
            "-m 'Update version number and CHANGELOG.md.'"
        ],
        [project_dir, "git tag #{tag}"],
        [package_dir_a, "mix hex.publish package --yes"],
        [project_dir, "git push origin main #{tag}"]
      ])
      expect(exit_status).to eql(0), output
    end

    it "publishes dependent packages" do
      prepare_elixir_project "packages_dir" => "packages/" do
        # Use same name as existing package so `mix deps.get` doesn't fail
        create_package :jason do
          create_package_mix :version => "1.1.2"
          add_changeset :patch
        end
        create_package :package_b do
          create_package_mix :version => "2.0.0", :dependencies => { :jason => "1.1.2" }
        end
      end
      confirm_publish_package
      output = run_publish_process

      project_dir = "/#{current_project}"
      package_dir_a = "#{project_dir}/packages/jason"
      package_dir_b = "#{project_dir}/packages/package_b"
      next_version_a = "1.1.3"
      next_version_b = "2.0.1"
      tag_a = "jason@#{next_version_a}"
      tag_b = "package_b@#{next_version_b}"

      expect(output).to include(<<~OUTPUT), output
        The following packages will be published (or not):
        - jason:
          Current version: jason@1.1.2
          Next version:    jason@1.1.3 (patch)
        - package_b:
          Current version: package_b@2.0.0
          Next version:    package_b@2.0.1 (patch)
      OUTPUT
      expect(output).to include(<<~OUTPUT), output
        # Updating package versions
        - jason:
          Current version: jason@1.1.2
          Next version:    jason@1.1.3 (patch)
        - package_b:
          Current version: package_b@2.0.0
          Next version:    package_b@2.0.1 (patch)
      OUTPUT

      in_project do
        in_package :jason do
          expect(File.read("mix.exs")).to include(%(version: "#{next_version_a}",))
          expect(current_package_changeset_files.length).to eql(0)

          changelog = File.read("CHANGELOG.md")
          expect_changelog_to_include_version_header(changelog, next_version_a)
          expect_changelog_to_include_release_notes(changelog, :patch)
        end

        in_package :package_b do
          expect(File.read("mix.exs")).to include(%(version: "#{next_version_b}",))
          expect(current_package_changeset_files.length).to eql(0)

          changelog = File.read("CHANGELOG.md")
          expect_changelog_to_include_version_header(changelog, next_version_b)
          expect_changelog_to_include_package_bump(changelog, "jason", next_version_a)
        end

        expect(local_changes?).to be_falsy, local_changes.inspect
        expect(commited_files).to eql([
          "packages/jason/.changesets/1_patch.md",
          "packages/jason/CHANGELOG.md",
          "packages/jason/mix.exs",
          "packages/package_b/CHANGELOG.md",
          "packages/package_b/mix.exs"
        ])
      end

      expect(performed_commands).to eql([
        [package_dir_a, "mix deps.get"],
        [package_dir_b, "mix deps.get"],
        [project_dir, "git tag --list #{tag_a} #{tag_b}"],
        [package_dir_a, "mix compile"],
        [package_dir_b, "mix compile"],
        [project_dir, "git add -A"],
        [
          project_dir,
          "git commit -m 'Publish packages' " \
            "-m 'Update version number and CHANGELOG.md.\n\n- #{tag_a}\n- #{tag_b}'"
        ],
        [project_dir, "git tag #{tag_a}"],
        [project_dir, "git tag #{tag_b}"],
        [package_dir_a, "mix hex.publish package --yes"],
        [package_dir_b, "mix hex.publish package --yes"],
        [project_dir, "git push origin main #{tag_a} #{tag_b}"]
      ])
      expect(exit_status).to eql(0), output
    end
  end

  def run_publish_process(failed_commands: [], stubbed_commands: nil)
    stubbed_commands ||= [/^mix hex.publish package --yes/, /^git push/]
    output =
      capture_stdout do
        in_project do
          add_changeset(:patch)

          perform_commands do
            fail_commands failed_commands do
              stub_commands stubbed_commands do
                run_bootstrap
                run_publish
              end
            end
          end
        end
      end
    strip_changeset_output output
  end
end
