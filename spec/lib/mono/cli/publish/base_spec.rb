# frozen_string_literal: true

RSpec.describe Mono::Cli::Publish do
  include PublishHelper

  around { |example| with_mock_stdin { example.run } }

  context "with unknown language project" do
    context "with single repo" do
      it "prints an error and exits" do
        prepare_project :unknown_single
        output = run_publish(:lang => :unknown)

        expect(output).to include("UnknownLanguageError: Unknown language configured"), output
        expect(exit_status).to eql(1), output
      end
    end

    context "with mono repo" do
      it "prints an error and exits" do
        prepare_project :unknown_mono
        output = run_publish(:lang => :unknown)

        expect(output).to include("UnknownLanguageError: Unknown language configured"), output
        expect(exit_status).to eql(1), output
      end
    end
  end

  context "without changes in the package" do
    it "exits with an error" do
      prepare_ruby_project do
        create_ruby_package_files :name => "mygem", :version => "1.2.3"
      end
      output = run_publish(:lang => :ruby)

      expect(output).to include("No packages found to publish! No changes detected.")
      expect(performed_commands).to be_empty
      expect(exit_status).to eql(1), output
    end
  end

  context "with uncommitted changes" do
    it "exits with an error" do
      prepare_ruby_project do
        create_ruby_package_files :name => "mygem", :version => "1.2.3"
        add_changeset(:patch)
      end
      in_project { FileUtils.touch "uncommited_file" }
      output = run_publish(:lang => :ruby)

      expect(performed_commands).to be_empty
      expect(output).to include("Error: There are local changes before building.")
      expect(exit_status).to eql(1), output
    end
  end

  context "when the version tag already exists" do
    it "exits with an error" do
      prepare_ruby_project do
        create_ruby_package_files :name => "mygem", :version => "1.2.3"
        add_changeset(:patch)
        File.write(".git/refs/tags/v1.2.4", "0123456789abcdef0123456789abcdef01234567")
      end
      output = run_publish(:lang => :ruby)

      expect(performed_commands).to eq([
        ["/custom_project_project", "git tag --list v1.2.4"]
      ])
      expect(output).to include("Error: The Git tags for packages to be published " \
        'already exist: "v1.2.4"')
      expect(exit_status).to eql(1), output
    end
  end

  describe "changeset preview" do
    context "with single package project" do
      it "prints changeset previews in the package summary" do
        prepare_ruby_project do
          create_ruby_package_files :name => "mygem", :version => "1.2.3"
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
        output = run_publish(:lang => :ruby, :strip_changeset_output => false)

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

        expect(performed_commands).to eql([
          ["/custom_project_project", "git tag --list v2.0.0"]
        ])
        expect(exit_status).to eql(1), output
      end
    end

    context "with multi package project" do
      it "prints changeset previews in the package summary" do
        prepare_ruby_project "packages_dir" => "packages/" do
          create_package :package_a do
            create_ruby_package_files :name => "package_a", :version => "1.2.3"
            add_changeset(:patch, :message => "a" * 101) # Limits to 100 characters in preview
            add_changeset(:major, :message => "This is a major changeset bump.\nLine 2.\nLine 3.")
            add_changeset(:minor)
          end
          create_package :package_b do
            create_ruby_package_files :name => "package_b", :version => "1.2.3"
            add_changeset(:patch, :message => "Changeset with indenting.\n  - item 1\n  - item 2")
          end
          create_package :package_c do
            create_ruby_package_files :name => "package_c", :version => "1.2.3"
          end
        end
        do_not_publish_package
        output = run_publish(:lang => :ruby, :strip_changeset_output => false)

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

        expect(performed_commands).to eql([
          ["/custom_project_project", "git tag --list package_a@2.0.0 package_b@1.2.4"]
        ])
        expect(exit_status).to eql(1), output
      end
    end
  end

  context "when not confirming publishing" do
    it "exits without making changes" do
      original_commit_count = nil
      prepare_ruby_project do
        create_ruby_package_files :name => "mygem", :version => "1.2.3"
        create_changelog
        add_changeset(:patch)
        original_commit_count = commit_count
      end
      do_not_publish_package
      output = run_publish(:lang => :ruby)

      expect(output).to have_publish_summary(
        :custom_project_project => { :old => "v1.2.3", :new => "v1.2.4", :bump => :patch }
      )
      expect(output).to_not include("# Updating package versions"), output
      expect(output).to_not include("Mono error was encountered"), output

      in_project do
        # Does not commit any changes during the publish process on exit
        expect(commit_count).to eql(original_commit_count)

        expect(read_ruby_gem_version_file).to have_ruby_version("1.2.3")
        expect(current_package_changeset_files.length).to eql(1)

        changelog = read_changelog_file
        expect(changelog).to_not include("1.2.4")

        expect(local_changes?).to be_falsy, local_changes.inspect
      end

      expect(performed_commands).to eql([
        ["/custom_project_project", "git tag --list v1.2.4"]
      ])
      expect(exit_status).to eql(1), output
    end
  end

  context "without CHANGELOG" do
    it "commits the CHANGELOG" do
      prepare_ruby_project do
        create_ruby_package_files :name => "mygem", :version => "1.2.3"
        create_changelog
        add_changeset(:patch)
        FileUtils.rm("CHANGELOG.md")
        commit_changes "Remove CHANGELOG.md"
      end
      confirm_publish_package
      output = run_publish(:lang => :ruby)

      project_dir = current_project_path
      next_version = "1.2.4"

      expect(output).to has_publish_and_update_summary(
        :custom_project_project => { :old => "v1.2.3", :new => "v1.2.4", :bump => :patch }
      )

      in_project do
        changelog = read_changelog_file
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
        [project_dir, "git tag --list v#{next_version}"],
        [project_dir, "gem build"],
        [project_dir, "git add -A"],
        [
          project_dir,
          "git commit -m 'Publish package v#{next_version}' " \
            "-m 'Update version number and CHANGELOG.md.'"
        ],
        [project_dir, "git tag v#{next_version}"],
        [project_dir, "gem push mygem-#{next_version}.gem"],
        [project_dir, "git push origin main v#{next_version}"]
      ])
      expect(exit_status).to eql(0), output
    end
  end

  context "with --alpha option" do
    it "publishes an alpha prerelease" do
      prepare_ruby_project do
        create_ruby_package_files :name => "mygem", :version => "1.2.3"
        add_changeset(:patch)
      end
      confirm_publish_package
      output = run_publish(["--alpha"], :lang => :ruby)

      project_dir = current_project_path
      next_version = "1.2.4.alpha.1"

      expect(output).to has_publish_and_update_summary(
        :custom_project_project => { :old => "v1.2.3", :new => "v1.2.4.alpha.1", :bump => :patch }
      )

      in_project do
        expect(read_ruby_gem_version_file).to have_ruby_version(next_version)
        expect(current_package_changeset_files.length).to eql(0)

        changelog = read_changelog_file
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
        [project_dir, "git tag --list v#{next_version}"],
        [project_dir, "gem build"],
        [project_dir, "git add -A"],
        [
          project_dir,
          "git commit -m 'Publish package v#{next_version}' " \
            "-m 'Update version number and CHANGELOG.md.'"
        ],
        [project_dir, "git tag v#{next_version}"],
        [project_dir, "gem push mygem-#{next_version}.gem"],
        [project_dir, "git push origin main v#{next_version}"]
      ])
      expect(exit_status).to eql(0), output
    end

    it "publishes an incremented alpha prerelease" do
      prepare_new_project do
        create_mono_config "language" => "ruby"
        create_ruby_package_files :name => "mygem", :version => "1.2.3.alpha.1"
        add_changeset(:patch)
      end
      confirm_publish_package
      output = run_publish(["--alpha"], :lang => :ruby)

      project_dir = current_project_path
      next_version = "1.2.3.alpha.2"

      expect(output).to has_publish_and_update_summary(
        :custom_project_project => {
          :old => "v1.2.3.alpha.1",
          :new => "v1.2.3.alpha.2",
          :bump => :patch
        }
      )

      in_project do
        expect(read_ruby_gem_version_file).to have_ruby_version(next_version)
        expect(current_package_changeset_files.length).to eql(0)

        changelog = read_changelog_file
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
        [project_dir, "git tag --list v#{next_version}"],
        [project_dir, "gem build"],
        [project_dir, "git add -A"],
        [
          project_dir,
          "git commit -m 'Publish package v#{next_version}' " \
            "-m 'Update version number and CHANGELOG.md.'"
        ],
        [project_dir, "git tag v#{next_version}"],
        [project_dir, "gem push mygem-#{next_version}.gem"],
        [project_dir, "git push origin main v#{next_version}"]
      ])
      expect(exit_status).to eql(0), output
    end
  end

  context "with prerelease" do
    it "publishes a final release with changesets" do
      prepare_new_project do
        create_mono_config "language" => "ruby"
        create_ruby_package_files :name => "mygem", :version => "1.2.3.alpha.1"
        add_changeset :patch
      end
      confirm_publish_package
      output = run_publish(:lang => :ruby)

      project_dir = current_project_path
      next_version = "1.2.3"

      expect(output).to has_publish_and_update_summary(
        :custom_project_project => {
          :old => "v1.2.3.alpha.1",
          :new => "v1.2.3",
          :bump => :patch
        }
      )

      in_project do
        expect(read_ruby_gem_version_file).to have_ruby_version(next_version)
        expect(current_package_changeset_files.length).to eql(0)

        changelog = read_changelog_file
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
        [project_dir, "git tag --list v#{next_version}"],
        [project_dir, "gem build"],
        [project_dir, "git add -A"],
        [
          project_dir,
          "git commit -m 'Publish package v#{next_version}' " \
            "-m 'Update version number and CHANGELOG.md.'"
        ],
        [project_dir, "git tag v#{next_version}"],
        [project_dir, "gem push mygem-#{next_version}.gem"],
        [project_dir, "git push origin main v#{next_version}"]
      ])
      expect(exit_status).to eql(0), output
    end

    it "publishes a final release without changesets" do
      prepare_new_project do
        create_mono_config "language" => "ruby"
        create_ruby_package_files :name => "mygem", :version => "1.2.3.alpha.1"
      end
      confirm_publish_package
      output = run_publish(:lang => :ruby)

      project_dir = current_project_path
      next_version = "1.2.3"

      expect(output).to has_publish_and_update_summary(
        :custom_project_project => {
          :old => "v1.2.3.alpha.1",
          :new => "v1.2.3",
          :bump => :patch
        }
      )

      in_project do
        expect(read_ruby_gem_version_file).to have_ruby_version(next_version)
        expect(current_package_changeset_files.length).to eql(0)

        changelog = read_changelog_file
        expect_changelog_to_include_version_header(changelog, next_version)
        expect_changelog_to_include_message(changelog, :patch, "Package release.")

        expect(local_changes?).to be_falsy, local_changes.inspect
        expect(commited_files).to eql([
          "CHANGELOG.md",
          "lib/example/version.rb"
        ])
      end

      expect(performed_commands).to eql([
        [project_dir, "git tag --list v#{next_version}"],
        [project_dir, "gem build"],
        [project_dir, "git add -A"],
        [
          project_dir,
          "git commit -m 'Publish package v#{next_version}' " \
            "-m 'Update version number and CHANGELOG.md.'"
        ],
        [project_dir, "git tag v#{next_version}"],
        [project_dir, "gem push mygem-#{next_version}.gem"],
        [project_dir, "git push origin main v#{next_version}"]
      ])
      expect(exit_status).to eql(0), output
    end

    it "without changes doesn't publish another prerelease" do
      prepare_new_project do
        create_mono_config "language" => "ruby"
        create_ruby_package_files :name => "mygem", :version => "1.2.3.alpha.1"
      end
      confirm_publish_package
      output = run_publish(["--alpha"], :lang => :ruby)

      expect(output).to include("Mono::Error: No packages found to publish! No changes detected.")
      expect(performed_commands).to eql([])
      expect(exit_status).to eql(1), output
    end
  end

  context "with a prerelease flag and tag option" do
    it "exits with an error" do
      prepare_new_project do
        create_mono_config "language" => "ruby"
        create_ruby_package_files :name => "mygem", :version => "1.2.3"
      end
      confirm_publish_package
      output = run_publish(["--alpha", "--tag", "beta"], :lang => :ruby)

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
      prepare_new_project do
        create_mono_config "language" => "ruby"
        create_ruby_package_files :name => "mygem", :version => "1.2.3"
        add_changeset(:patch)
        add_hook("build", "pre", "echo before build")
        add_hook("build", "post", "echo after build")
        add_hook("publish", "pre", "echo before publish")
        add_hook("publish", "post", "echo after publish")
        commit_changes("Update mono config")
      end
      confirm_publish_package
      output = run_publish(:lang => :ruby)

      project_dir = current_project_path
      next_version = "1.2.4"
      expect(performed_commands).to eql([
        [project_dir, "git tag --list v#{next_version}"],
        [project_dir, "echo before build"],
        [project_dir, "gem build"],
        [project_dir, "echo after build"],
        [project_dir, "git add -A"],
        [
          project_dir,
          "git commit -m 'Publish package v#{next_version}' " \
            "-m 'Update version number and CHANGELOG.md.'"
        ],
        [project_dir, "git tag v#{next_version}"],
        [project_dir, "echo before publish"],
        [project_dir, "gem push mygem-#{next_version}.gem"],
        [project_dir, "echo after publish"],
        [project_dir, "git push origin main v#{next_version}"]
      ])
      expect(exit_status).to eql(0), output
    end
  end

  context "with only one package selected in a mono repo" do
    it "publishes only the selected package" do
      prepare_ruby_project "packages_dir" => "packages/" do
        create_package :package_a do
          create_ruby_package_files :name => "package_a", :version => "1.2.3"
          add_changeset(:patch)
        end
        create_package :package_b do
          create_ruby_package_files :name => "package_b", :version => "1.2.3"
          add_changeset(:patch)
        end
      end
      confirm_publish_package
      output = run_publish(["--package", "package_a"], :lang => :ruby)

      project_dir = current_project_path
      package_a_dir = File.join(project_dir, project_package_path(:package_a))
      next_version = "1.2.4"
      tag = "package_a@#{next_version}"

      expect(performed_commands).to eql([
        [project_dir, "git tag --list #{tag}"],
        [package_a_dir, "gem build"],
        [project_dir, "git add -A"],
        [
          project_dir,
          "git commit -m 'Publish package #{tag}' " \
            "-m 'Update version number and CHANGELOG.md.'"
        ],
        [project_dir, "git tag #{tag}"],
        [project_dir, "gem push #{project_package_path(:package_a)}/package_a-#{next_version}.gem"],
        [project_dir, "git push origin main #{tag}"]
      ])
      expect(exit_status).to eql(0), output
    end
  end

  context "with multiple packages selected in a mono repo" do
    it "publishes only the selected packages" do
      prepare_ruby_project "packages_dir" => "packages/" do
        create_package :package_a do
          create_ruby_package_files :name => "package_a", :version => "1.2.3"
          add_changeset(:patch)
        end
        create_package :package_b do
          create_ruby_package_files :name => "package_b", :version => "1.2.3"
          add_changeset(:patch)
        end
      end
      confirm_publish_package
      output = run_publish(["--package", "package_a,package_b"], :lang => :ruby)

      project_dir = current_project_path
      package_a_dir = "#{project_dir}/packages/package_a"
      package_b_dir = "#{project_dir}/packages/package_b"
      next_version = "1.2.4"
      tag1 = "package_a@#{next_version}"
      tag2 = "package_b@#{next_version}"

      expect(performed_commands).to eql([
        [project_dir, "git tag --list #{tag1} #{tag2}"],
        [package_a_dir, "gem build"],
        [package_b_dir, "gem build"],
        [project_dir, "git add -A"],
        [
          project_dir,
          "git commit -m 'Publish packages' " \
            "-m 'Update version number and CHANGELOG.md.\n\n" \
            "- #{tag1}\n" \
            "- #{tag2}'"
        ],
        [project_dir, "git tag #{tag1}"],
        [project_dir, "git tag #{tag2}"],
        [project_dir, "gem push #{project_package_path(:package_a)}/package_a-#{next_version}.gem"],
        [project_dir, "gem push #{project_package_path(:package_b)}/package_b-#{next_version}.gem"],
        [project_dir, "git push origin main #{tag1} #{tag2}"]
      ])
      expect(exit_status).to eql(0), output
    end
  end

  context "with unknown packages selected in a mono repo" do
    it "exits with an error" do
      prepare_ruby_project "packages_dir" => "packages/" do
        create_package :package_a do
          create_ruby_package_files :name => "package_a", :version => "1.2.3"
          add_changeset(:patch)
        end
        create_package :package_b do
          create_ruby_package_files :name => "package_b", :version => "1.2.3"
          add_changeset(:patch)
        end
      end
      output = run_publish(["--package", "package_a,package_c"], :lang => :ruby)

      expect(output).to include(
        "Mono::PackageNotFound: The package with the name `package_c` could not be found."
      ), output
      expect(performed_commands).to eql([])
      expect(exit_status).to eql(1), output
    end
  end

  context "with failing publish command" do
    it "retries to publish" do
      fail_command = "exit 1"
      prepare_ruby_project do
        create_ruby_package_files :name => "mygem", :version => "1.2.3"
        add_changeset :patch
      end
      confirm_publish_package
      add_cli_input "y" # Retry command
      add_cli_input "n" # Don't retry command
      add_cli_input "n" # Don't rollback changes
      output = run_publish(
        :lang => :ruby,
        :stubbed_commands => [/^git push/],
        :failed_commands => [/^gem push/]
      )

      project_dir = current_project_path
      next_version = "1.2.4"

      expect(output).to include(<<~OUTPUT), output
        #{fail_command}
        Error: Command failed. Do you want to retry? (Y/n): #{fail_command}
        Error: Command failed. Do you want to retry? (Y/n):#{" "}
        A Mono error was encountered during the `mono publish` command. Stopping operation.

        Mono::Error: Command failed with status `1`
      OUTPUT

      expect(performed_commands).to eql([
        [project_dir, "git tag --list v#{next_version}"],
        [project_dir, "gem build"],
        [project_dir, "git add -A"],
        [
          project_dir,
          "git commit -m 'Publish package v#{next_version}' " \
            "-m 'Update version number and CHANGELOG.md.'"
        ],
        [project_dir, "git tag v#{next_version}"],
        [project_dir, "gem push mygem-#{next_version}.gem"]
      ])
      expect(exit_status).to eql(1), output
    end

    it "rolls back changes" do
      fail_command = "exit 1"
      prepare_ruby_project do
        create_ruby_package_files :name => "mygem", :version => "1.2.3"
        add_changeset :patch
      end
      confirm_publish_package
      add_cli_input "n" # Don't retry command
      add_cli_input "y" # Rollback changes
      output = run_publish(
        :lang => :ruby,
        :stubbed_commands => [
          /^git push/,
          # Happens after `## Untag package v1.2.4` in output,
          # stubbed because output contains commit hash
          /^git tag -d/
        ],
        :failed_commands => [/^gem push/]
      )

      project_dir = current_project_path
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
        [project_dir, "git tag --list v#{next_version}"],
        [project_dir, "gem build"],
        [project_dir, "git add -A"],
        [
          project_dir,
          "git commit -m 'Publish package v#{next_version}' " \
            "-m 'Update version number and CHANGELOG.md.'"
        ],
        [project_dir, "git tag v#{next_version}"],
        [project_dir, "gem push mygem-#{next_version}.gem"],
        [project_dir, "git tag -d v1.2.4"],
        [project_dir, "git reset --soft HEAD^"],
        [project_dir, "git restore --staged :/"],
        [project_dir, "git restore :/"]
      ])
      expect(exit_status).to eql(1), output
    end
  end

  context "with --no-git" do
    it "doesn't commit or push using Git" do
      prepare_ruby_project do
        create_ruby_package_files :name => "mygem", :version => "1.2.3"
        add_changeset :patch
      end
      confirm_publish_package
      output = run_publish(["--no-git"], :lang => :ruby)

      project_dir = current_project_path
      next_version = "1.2.4"

      in_project do
        expect(local_changes?).to be_truthy, local_changes.inspect
      end

      expect(performed_commands).to eql([
        [project_dir, "gem build"],
        [project_dir, "gem push mygem-#{next_version}.gem"]
      ])
      expect(exit_status).to eql(0), output
    end
  end
end
