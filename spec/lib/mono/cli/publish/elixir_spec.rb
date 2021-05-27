# frozen_string_literal: true

RSpec.describe Mono::Cli::Publish do
  include PublishHelper

  around { |example| with_mock_stdin { example.run } }

  context "with single Elixir package" do
    it "publishes the package" do
      prepare_project :elixir_single
      confirm_publish_package
      output =
        capture_stdout do
          in_project do
            add_changeset(:patch)

            perform_commands do
              stub_commands [/^mix hex.publish package --yes/, /^git push/] do
                run_bootstrap
                run_publish
              end
            end
          end
        end

      project_dir = "/elixir_single_project"
      next_version = "1.2.4"

      expect(output).to include(<<~OUTPUT), output
        The following packages will be published (or not):
        - elixir_single_project:
          Current version: v1.2.3
          Next version:    v1.2.4 (patch)
      OUTPUT
      expect(output).to include(<<~OUTPUT), output
        # Updating package versions
        - elixir_single_project:
          Current version: v1.2.3
          Next version:    v1.2.4 (patch)
      OUTPUT

      in_project do
        expect(File.read("mix.exs")).to include(%(@version "#{next_version}"))
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
        [project_dir, "mix compile"],
        [project_dir, "git add -A"],
        [project_dir, "git commit -m 'Publish packages [ci skip]' -m '- v#{next_version}'"],
        [project_dir, "git tag v#{next_version}"],
        [project_dir, "mix hex.publish package --yes"],
        [project_dir, "git push origin main v#{next_version}"]
      ])
      expect(exit_status).to eql(0), output
    end
  end

  context "with mono Elixir project" do
    it "publishes the package" do
      prepare_project :elixir_mono
      confirm_publish_package
      output =
        capture_stdout do
          in_project do
            in_package "package_one" do
              add_changeset(:patch)
            end

            perform_commands do
              stub_commands [/^mix hex.publish package --yes/, /^git push/] do
                run_bootstrap
                run_publish
              end
            end
          end
        end

      project_dir = "/elixir_mono_project"
      package_one_dir = "#{project_dir}/packages/package_one"
      package_two_dir = "#{project_dir}/packages/package_two"
      next_version = "1.2.4"
      tag = "package_one@#{next_version}"

      expect(output).to include(<<~OUTPUT), output
        The following packages will be published (or not):
        - package_one:
          Current version: package_one@1.2.3
          Next version:    package_one@1.2.4 (patch)
        - package_two: (Will not publish)
      OUTPUT
      expect(output).to include(<<~OUTPUT), output
        # Updating package versions
        - package_one:
          Current version: package_one@1.2.3
          Next version:    package_one@1.2.4 (patch)
      OUTPUT

      in_project do
        in_package "package_one" do
          expect(File.read("mix.exs")).to include(%(@version "#{next_version}"))
          expect(current_package_changeset_files.length).to eql(0)

          changelog = File.read("CHANGELOG.md")
          expect_changelog_to_include_version_header(changelog, next_version)
          expect_changelog_to_include_release_notes(changelog, :patch)
        end

        expect(local_changes?).to be_falsy, local_changes.inspect
        expect(commited_files).to eql([
          "packages/package_one/.changesets/1_patch.md",
          "packages/package_one/CHANGELOG.md",
          "packages/package_one/mix.exs"
        ])
      end

      expect(performed_commands).to eql([
        [package_one_dir, "mix deps.get"],
        [package_two_dir, "mix deps.get"],
        [package_one_dir, "mix compile"],
        [project_dir, "git add -A"],
        [project_dir, "git commit -m 'Publish packages [ci skip]' -m '- #{tag}'"],
        [project_dir, "git tag #{tag}"],
        [package_one_dir, "mix hex.publish package --yes"],
        [project_dir, "git push origin main #{tag}"]
      ])
      expect(exit_status).to eql(0), output
    end
  end
end
