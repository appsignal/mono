# frozen_string_literal: true

RSpec.describe Mono::Cli::Publish do
  include PublishHelper

  around { |example| with_mock_stdin { example.run } }

  context "with unknown language project" do
    context "with single repo" do
      it "prints an error and exits" do
        prepare_project :unknown_single
        output =
          capture_stdout do
            in_project { run_publish }
          end

        expect(output).to include("UnknownLanguageError: Unknown language configured"), output
        expect(exit_status).to eql(1), output
      end
    end

    context "with mono repo" do
      it "prints an error and exits" do
        prepare_project :unknown_mono
        output =
          capture_stdout do
            in_project { run_publish }
          end

        expect(output).to include("UnknownLanguageError: Unknown language configured"), output
        expect(exit_status).to eql(1), output
      end
    end
  end

  context "without changes in the package" do
    it "exits with an error" do
      prepare_project :ruby_single
      output =
        capture_stdout do
          in_project { run_publish }
        end

      expect(output).to include("No packages found to publish! No changes detected.")
      expect(performed_commands).to be_empty
      expect(exit_status).to eql(1), output
    end
  end

  context "with uncommitted changes" do
    it "exits with an error" do
      prepare_project :ruby_single
      output =
        capture_stdout do
          in_project do
            add_changeset(:patch)
            FileUtils.touch "uncommited_file"
            run_publish
          end
        end

      expect(performed_commands).to be_empty
      expect(output).to include("Error: There are local changes before building.")
      expect(exit_status).to eql(1), output
    end
  end

  context "when not confirming publishing" do
    it "exits without making changes" do
      prepare_project :ruby_single
      do_not_publish_package
      output =
        capture_stdout do
          in_project do
            add_changeset(:patch)
            original_commit_count = commit_count

            perform_commands do
              stub_commands [/^gem push/, /^git push/] do
                run_publish
              end
            end
            # Does not commit any changes during the publish process on exit
            expect(commit_count).to eql(original_commit_count)
          end
        end

      expect(output).to include(<<~OUTPUT), output
        The following packages will be published (or not):
        - ruby_single_project:
          Current version: v1.2.3
          Next version:    v1.2.4 (patch)
      OUTPUT
      expect(output).to_not include("# Updating package versions"), output
      expect(output).to_not include("Mono error was encountered"), output

      in_project do
        expect(File.read("lib/example/version.rb")).to include(%(VERSION = "1.2.3"))
        expect(current_package_changeset_files.length).to eql(1)

        changelog = File.read("CHANGELOG.md")
        expect(changelog).to_not include("1.2.4")

        expect(local_changes?).to be_falsy, local_changes.inspect
      end

      expect(performed_commands).to eql([])
      expect(exit_status).to eql(1), output
    end
  end

  context "without CHANGELOG" do
    it "commits the CHANGELOG" do
      prepare_project :ruby_single
      confirm_publish_package
      output =
        capture_stdout do
          in_project do
            add_changeset(:patch)
            FileUtils.rm("CHANGELOG.md")
            commit_changes "Remove CHANGELOG.md"

            perform_commands do
              stub_commands [/^gem push/, /^git push/] do
                run_publish
              end
            end
          end
        end

      project_dir = "/ruby_single_project"
      next_version = "1.2.4"

      expect(output).to include(<<~OUTPUT), output
        The following packages will be published (or not):
        - ruby_single_project:
          Current version: v1.2.3
          Next version:    v1.2.4 (patch)
      OUTPUT
      expect(output).to include(<<~OUTPUT), output
        # Updating package versions
        - ruby_single_project:
          Current version: v1.2.3
          Next version:    v1.2.4 (patch)
      OUTPUT

      in_project do
        changelog = File.read("CHANGELOG.md")
        expect_changelog_to_include_version_header(changelog, next_version)
        expect_changelog_to_include_release_notes(changelog, :patch)

        expect(local_changes?).to be_falsy, local_changes.inspect
        expect(commited_files).to eql([
          ".changesets/1_patch.md",
          "CHANGELOG.md",
          "lib/example/version.rb"
        ])
      end

      expect(performed_commands).to eql([
        [project_dir, "gem build"],
        [project_dir, "git add -A"],
        [project_dir, "git commit -m 'Publish packages [ci skip]' -m '- v#{next_version}'"],
        [project_dir, "git tag v#{next_version}"],
        [project_dir, "gem push ruby_single_project-#{next_version}.gem"],
        [project_dir, "git push origin main v#{next_version}"]
      ])
      expect(exit_status).to eql(0), output
    end
  end

  context "with --alpha option" do
    it "publishes an alpha prerelease" do
      prepare_project :ruby_single
      confirm_publish_package
      output =
        capture_stdout do
          in_project do
            add_changeset(:patch)

            perform_commands do
              stub_commands [/^gem push/, /^git push/] do
                run_publish(["--alpha"])
              end
            end
          end
        end

      project_dir = "/ruby_single_project"
      next_version = "1.2.4.alpha.1"

      expect(output).to include(<<~OUTPUT), output
        The following packages will be published (or not):
        - ruby_single_project:
          Current version: v1.2.3
          Next version:    v1.2.4.alpha.1 (patch)
      OUTPUT
      expect(output).to include(<<~OUTPUT), output
        # Updating package versions
        - ruby_single_project:
          Current version: v1.2.3
          Next version:    v1.2.4.alpha.1 (patch)
      OUTPUT

      in_project do
        expect(File.read("lib/example/version.rb")).to include(%(VERSION = "#{next_version}"))
        expect(current_package_changeset_files.length).to eql(0)

        changelog = File.read("CHANGELOG.md")
        expect_changelog_to_include_version_header(changelog, next_version)
        expect_changelog_to_include_release_notes(changelog, :patch)

        expect(local_changes?).to be_falsy, local_changes.inspect
        expect(commited_files).to eql([
          ".changesets/1_patch.md",
          "CHANGELOG.md",
          "lib/example/version.rb"
        ])
      end

      expect(performed_commands).to eql([
        [project_dir, "gem build"],
        [project_dir, "git add -A"],
        [project_dir, "git commit -m 'Publish packages [ci skip]' -m '- v#{next_version}'"],
        [project_dir, "git tag v#{next_version}"],
        [project_dir, "gem push ruby_single_project-#{next_version}.gem"],
        [project_dir, "git push origin main v#{next_version}"]
      ])
      expect(exit_status).to eql(0), output
    end
  end

  context "with hooks" do
    it "runs hooks around command" do
      prepare_project :ruby_single
      confirm_publish_package
      output =
        capture_stdout do
          in_project do
            add_changeset(:patch)
            add_hook("build", "pre", "echo before build")
            add_hook("build", "post", "echo after build")
            add_hook("publish", "pre", "echo before publish")
            add_hook("publish", "post", "echo after publish")
            commit_changes("Update mono config")
            perform_commands do
              stub_commands [/^gem push/, /^git push/] do
                run_publish
              end
            end
          end
        end

      project_dir = "/ruby_single_project"
      next_version = "1.2.4"
      expect(performed_commands).to eql([
        [project_dir, "echo before build"],
        [project_dir, "gem build"],
        [project_dir, "echo after build"],
        [project_dir, "git add -A"],
        [project_dir, "git commit -m 'Publish packages [ci skip]' -m '- v#{next_version}'"],
        [project_dir, "git tag v#{next_version}"],
        [project_dir, "echo before publish"],
        [project_dir, "gem push ruby_single_project-#{next_version}.gem"],
        [project_dir, "echo after publish"],
        [project_dir, "git push origin main v#{next_version}"]
      ])
      expect(exit_status).to eql(0), output
    end
  end

  context "with only one package selected in a mono repo" do
    it "only publishes only the selected package" do
      prepare_project :elixir_mono
      confirm_publish_package
      output =
        capture_stdout do
          in_project do
            in_package "package_one" do
              add_changeset(:patch)
            end
            in_package "package_two" do
              add_changeset(:patch)
            end

            perform_commands do
              stub_commands [/^mix hex.publish package --yes/, /^git push/] do
                run_bootstrap
                run_publish ["--package", "package_one"]
              end
            end
          end
        end

      project_dir = "/elixir_mono_project"
      package_one_dir = "#{project_dir}/packages/package_one"
      package_two_dir = "#{project_dir}/packages/package_two"
      next_version = "1.2.4"
      tag = "package_one@#{next_version}"

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

  context "with multiple package selected in a mono repo" do
    it "only publishes only the selected packages" do
      prepare_project :elixir_mono
      confirm_publish_package
      output =
        capture_stdout do
          in_project do
            in_package "package_one" do
              add_changeset(:patch)
            end
            in_package "package_two" do
              add_changeset(:patch)
            end

            perform_commands do
              stub_commands [/^mix hex.publish package --yes/, /^git push/] do
                run_bootstrap
                run_publish ["--package", "package_one,package_two"]
              end
            end
          end
        end

      project_dir = "/elixir_mono_project"
      package_one_dir = "#{project_dir}/packages/package_one"
      package_two_dir = "#{project_dir}/packages/package_two"
      next_version = "1.2.4"
      tag1 = "package_one@#{next_version}"
      tag2 = "package_two@#{next_version}"

      expect(performed_commands).to eql([
        [package_one_dir, "mix deps.get"],
        [package_two_dir, "mix deps.get"],
        [package_one_dir, "mix compile"],
        [package_two_dir, "mix compile"],
        [project_dir, "git add -A"],
        [project_dir, "git commit -m 'Publish packages [ci skip]' -m '- #{tag1}\n- #{tag2}'"],
        [project_dir, "git tag #{tag1}"],
        [project_dir, "git tag #{tag2}"],
        [package_one_dir, "mix hex.publish package --yes"],
        [package_two_dir, "mix hex.publish package --yes"],
        [project_dir, "git push origin main #{tag1} #{tag2}"]
      ])
      expect(exit_status).to eql(0), output
    end
  end

  context "with unknown packages selected in a mono repo" do
    it "exits with an error" do
      prepare_project :elixir_mono
      output =
        capture_stdout do
          in_project do
            run_publish(["--package", "package_one,package_three"])
          end
        end

      expect(output).to include(
        "Mono::PackageNotFound: The package with the name `package_three` could not be found."
      ), output
      expect(performed_commands).to eql([])
      expect(exit_status).to eql(1), output
    end
  end
end
