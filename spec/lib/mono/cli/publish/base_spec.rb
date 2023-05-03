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

  describe "changeset preview" do
    context "with single package project" do
      it "prints changeset previews in the package summary" do
        prepare_elixir_project do
          create_package_mix :version => "1.2.3"
          add_changeset :patch,
            :type => :change,
            :message => "a" * 101 # Limits to 100 characters in preview
          add_changeset :major,
            :type => :change,
            :message => "This is a major changeset bump.\nLine 2.\nLine 3."
          add_changeset :minor, :type => :change
          add_changeset :patch,
            :type => :add,
            :message => "a" * 101 # Limits to 100 characters in preview
          add_changeset :major,
            :type => :add,
            :message => "This is a major changeset bump.\nLine 2.\nLine 3."
          add_changeset :minor, :type => :add
        end
        do_not_publish_package
        output =
          capture_stdout do
            in_project do
              perform_commands do
                stub_commands [/^mix hex.publish package --yes/, /^git push/] do
                  run_publish
                end
              end
            end
          end

        # Sorts changesets by highest version bump first
        expect(output).to include(<<~OUTPUT), output
          The following packages will be published (or not):
          - custom_project_project:
            Current version: v1.2.3
            Next version:    v2.0.0 (major)
            Changesets:
            - Added - major: ./.changesets/5_major.md
                This is a major changeset bump. Line 2. Line 3.
            - Added - minor: ./.changesets/6_minor.md
                This is a minor changeset bump.
            - Added - patch: ./.changesets/4_patch.md
                #{"a" * 100}...
            - Changed - major: ./.changesets/2_major.md
                This is a major changeset bump. Line 2. Line 3.
            - Changed - minor: ./.changesets/3_minor.md
                This is a minor changeset bump.
            - Changed - patch: ./.changesets/1_patch.md
                #{"a" * 100}...
        OUTPUT

        expect(performed_commands).to eql([])
        expect(exit_status).to eql(1), output
      end
    end

    context "with multi package project" do
      it "prints changeset previews in the package summary" do
        prepare_elixir_project "packages_dir" => "packages/" do
          create_package :package_a do
            create_package_mix :version => "1.2.3"
            add_changeset(:patch, :message => "a" * 101) # Limits to 100 characters in preview
            add_changeset(:major, :message => "This is a major changeset bump.\nLine 2.\nLine 3.")
            add_changeset(:minor)
          end
          create_package :package_b do
            create_package_mix :version => "1.2.3"
            add_changeset(:patch, :message => "Changeset with indenting.\n  - item 1\n  - item 2")
          end
          create_package :package_c do
            create_package_mix :version => "1.2.3"
          end
        end
        do_not_publish_package
        output =
          capture_stdout do
            in_project do
              perform_commands do
                stub_commands [/^mix hex.publish package --yes/, /^git push/] do
                  run_publish
                end
              end
            end
          end

        # Sorts changesets by highest version bump first
        expect(output).to include(<<~OUTPUT), output
          The following packages will be published (or not):
          - package_a:
            Current version: package_a@1.2.3
            Next version:    package_a@2.0.0 (major)
            Changesets:
            - Added - major: packages/package_a/.changesets/2_major.md
                This is a major changeset bump. Line 2. Line 3.
            - Added - minor: packages/package_a/.changesets/3_minor.md
                This is a minor changeset bump.
            - Added - patch: packages/package_a/.changesets/1_patch.md
                #{"a" * 100}...
          - package_b:
            Current version: package_b@1.2.3
            Next version:    package_b@1.2.4 (patch)
            Changesets:
            - Added - patch: packages/package_b/.changesets/4_patch.md
                Changeset with indenting. - item 1 - item 2
          - package_c: (Will not publish)
        OUTPUT

        expect(performed_commands).to eql([])
        expect(exit_status).to eql(1), output
      end
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
        [project_dir, "git commit -m 'Publish packages' -m '- v#{next_version}'"],
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
        [project_dir, "git commit -m 'Publish packages' -m '- v#{next_version}'"],
        [project_dir, "git tag v#{next_version}"],
        [project_dir, "gem push ruby_single_project-#{next_version}.gem"],
        [project_dir, "git push origin main v#{next_version}"]
      ])
      expect(exit_status).to eql(0), output
    end

    it "publishes an incremented alpha prerelease" do
      prepare_new_project do
        create_mono_config "language" => "ruby"
        create_ruby_package_files :name => "package_a", :version => "1.2.3.alpha.1"
        add_changeset :patch
      end
      confirm_publish_package
      output =
        capture_stdout do
          in_project do
            perform_commands do
              stub_commands [/^gem push/, /^git push/] do
                run_publish(["--alpha"])
              end
            end
          end
        end

      project_dir = "/#{current_project}"
      next_version = "1.2.3.alpha.2"

      expect(output).to include(<<~OUTPUT), output
        The following packages will be published (or not):
        - #{current_project}:
          Current version: v1.2.3.alpha.1
          Next version:    v1.2.3.alpha.2 (patch)
      OUTPUT
      expect(output).to include(<<~OUTPUT), output
        # Updating package versions
        - #{current_project}:
          Current version: v1.2.3.alpha.1
          Next version:    v1.2.3.alpha.2 (patch)
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
        [project_dir, "git commit -m 'Publish packages' -m '- v#{next_version}'"],
        [project_dir, "git tag v#{next_version}"],
        [project_dir, "gem push package_a-#{next_version}.gem"],
        [project_dir, "git push origin main v#{next_version}"]
      ])
      expect(exit_status).to eql(0), output
    end
  end

  context "with prerelease" do
    it "publishes a final release with changesets" do
      prepare_new_project do
        create_mono_config "language" => "ruby"
        create_ruby_package_files :name => "package_a", :version => "1.2.3.alpha.1"
        add_changeset :patch
      end
      confirm_publish_package
      output =
        capture_stdout do
          in_project do
            perform_commands do
              stub_commands [/^gem push/, /^git push/] do
                run_publish
              end
            end
          end
        end

      project_dir = "/#{current_project}"
      next_version = "1.2.3"

      expect(output).to include(<<~OUTPUT), output
        The following packages will be published (or not):
        - #{current_project}:
          Current version: v1.2.3.alpha.1
          Next version:    v1.2.3 (patch)
      OUTPUT
      expect(output).to include(<<~OUTPUT), output
        # Updating package versions
        - #{current_project}:
          Current version: v1.2.3.alpha.1
          Next version:    v1.2.3 (patch)
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
        [project_dir, "git commit -m 'Publish packages' -m '- v#{next_version}'"],
        [project_dir, "git tag v#{next_version}"],
        [project_dir, "gem push package_a-#{next_version}.gem"],
        [project_dir, "git push origin main v#{next_version}"]
      ])
      expect(exit_status).to eql(0), output
    end

    it "publishes a final release without changesets" do
      prepare_new_project do
        create_mono_config "language" => "ruby"
        create_ruby_package_files :name => "package_a", :version => "1.2.3.alpha.1"
      end
      confirm_publish_package
      output =
        capture_stdout do
          in_project do
            perform_commands do
              stub_commands [/^gem push/, /^git push/] do
                run_publish
              end
            end
          end
        end

      project_dir = "/#{current_project}"
      next_version = "1.2.3"

      expect(output).to include(<<~OUTPUT), output
        The following packages will be published (or not):
        - #{current_project}:
          Current version: v1.2.3.alpha.1
          Next version:    v1.2.3 (patch)
      OUTPUT
      expect(output).to include(<<~OUTPUT), output
        # Updating package versions
        - #{current_project}:
          Current version: v1.2.3.alpha.1
          Next version:    v1.2.3 (patch)
      OUTPUT

      in_project do
        expect(File.read("lib/example/version.rb")).to include(%(VERSION = "#{next_version}"))
        expect(current_package_changeset_files.length).to eql(0)

        changelog = File.read("CHANGELOG.md")
        expect_changelog_to_include_version_header(changelog, next_version)
        expect_changelog_to_include_message(changelog, :patch, "Package release.")

        expect(local_changes?).to be_falsy, local_changes.inspect
        expect(commited_files).to eql([
          "CHANGELOG.md",
          "lib/example/version.rb"
        ])
      end

      expect(performed_commands).to eql([
        [project_dir, "gem build"],
        [project_dir, "git add -A"],
        [project_dir, "git commit -m 'Publish packages' -m '- v#{next_version}'"],
        [project_dir, "git tag v#{next_version}"],
        [project_dir, "gem push package_a-#{next_version}.gem"],
        [project_dir, "git push origin main v#{next_version}"]
      ])
      expect(exit_status).to eql(0), output
    end

    it "without changes doesn't publish another prerelease" do
      prepare_new_project do
        create_mono_config "language" => "ruby"
        create_ruby_package_files :name => "package_a", :version => "1.2.3.alpha.1"
      end
      confirm_publish_package
      output =
        capture_stdout do
          in_project do
            perform_commands do
              stub_commands [/^gem push/, /^git push/] do
                run_publish(["--alpha"])
              end
            end
          end
        end

      expect(output).to include("Mono::Error: No packages found to publish! No changes detected.")
      expect(performed_commands).to eql([])
      expect(exit_status).to eql(1), output
    end
  end

  context "with a prerelease flag and tag option" do
    it "exits with an error" do
      prepare_new_project do
        create_mono_config "language" => "ruby"
        create_ruby_package_files :name => "package_a", :version => "1.2.3"
      end
      confirm_publish_package
      output =
        capture_stdout do
          in_project do
            perform_commands do
              run_publish(["--alpha", "--tag", "beta"])
            end
          end
        end

      expect(output).to include(
        "Mono::Error: Error: Both a prerelease flag (--alpha, --beta, --rc) and " \
          "--tag options are set."
      )
      expect(performed_commands).to eql([])
      expect(exit_status).to eql(1), output
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
        [project_dir, "git commit -m 'Publish packages' -m '- v#{next_version}'"],
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
        [project_dir, "git commit -m 'Publish packages' -m '- #{tag}'"],
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
        [project_dir, "git commit -m 'Publish packages' -m '- #{tag1}\n- #{tag2}'"],
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
