# frozen_string_literal: true

RSpec.describe Mono::Cli::Publish do
  include PublishHelper

  around { |example| with_mock_stdin { example.run } }

  context "with a single Ruby package in dry-run mode" do
    it "shows what it would do without publishing" do
      prepare_ruby_project do
        create_ruby_package_files :name => "mygem", :version => "1.2.3"
        add_changeset :patch
      end
      confirm_publish_package
      output = with_dry_run { run_publish(:lang => :ruby) }

      project_dir = current_project_path
      next_version = "1.2.4"
      tag = "v#{next_version}"

      expect(output).to has_publish_and_update_summary(
        current_project => { :old => "v1.2.3", :new => "v1.2.4", :bump => :patch }
      )

      # The read-only tag check runs for real, so it is not printed with a
      # dry-run marker. Every effectful command is printed with the marker
      # instead of being run.
      expect(output).to_not include("[dry-run] git tag --list")
      expect(output).to include("[dry-run] gem build")
      expect(output).to include("[dry-run] git add -A")
      expect(output).to include("[dry-run] git commit")
      expect(output).to include("[dry-run] git tag #{tag}")
      # The gem was not built, so there is no gem file to push. The dry run says
      # what it would push instead of failing. It names the gem file after the
      # package, so a locked release with several packages can be told apart.
      expect(output).to include(
        "[dry-run] gem push #{current_project}-#{next_version}.gem " \
          "(skipped; no gem was built in dry-run mode)"
      )

      in_project do
        # The version file, changelog and changeset files are still updated on
        # disk, matching the documented dry-run behavior.
        expect(read_ruby_gem_version_file).to have_ruby_version(next_version)
        expect(current_package_changeset_files.length).to eql(0)
        changelog = read_changelog_file
        expect_changelog_to_include_version_header(changelog, next_version)
        expect_changelog_to_include_release_notes(changelog, :patch)

        # The release commit is not created, so those on-disk changes are left
        # uncommitted.
        expect(local_changes?).to be_truthy
      end

      # The effectful commands appear in the plan, so a dry run shows the full
      # sequence it would run. The `gem push` command is absent because the gem
      # was never built.
      expect(performed_commands).to eql([
        [project_dir, "git tag --list #{tag}"],
        [project_dir, "gem build"],
        [project_dir, "git add -A"],
        [
          project_dir,
          "git commit -m 'Publish package #{tag}' " \
            "-m 'Update version number and CHANGELOG.md.'"
        ],
        [project_dir, version_tag_command(tag)],
        [project_dir, "git push origin main"],
        [project_dir, "git push origin #{tag}"]
      ])
      expect(exit_status).to eql(0), output
    end
  end

  context "with version_lock and a packages map in dry-run mode" do
    it "shows the locked release without publishing" do
      prepare_ruby_project(
        "packages" => { "root_gem" => ".", "sub_gem" => "packages/sub_gem" },
        "version_lock" => true
      ) do
        create_ruby_package_files :name => "root_gem", :version => "1.2.3"
        create_changelog
        add_changeset :minor
        create_package :sub_gem do
          create_ruby_package_files :name => "sub_gem", :version => "1.2.3"
        end
      end
      confirm_publish_package
      output = with_dry_run { run_publish(:lang => :ruby) }

      project_dir = current_project_path
      sub_gem_dir = "#{project_dir}/packages/sub_gem"
      next_version = "1.3.0"
      tag = "v#{next_version}"

      expect(output).to has_publish_and_update_summary(
        :root_gem => { :old => "v1.2.3", :new => "v1.3.0", :bump => :minor },
        :sub_gem => { :old => "v1.2.3", :new => "v1.3.0", :bump => :minor }
      )

      expect(output).to include("[dry-run] git add -A")
      expect(output).to include("[dry-run] git commit")
      expect(output).to include("[dry-run] git tag #{tag}")

      # Each package names its own gem file, so the two pushes of a locked
      # release can be told apart even though the gems were not built.
      expect(output).to include(
        "[dry-run] gem push root_gem-#{next_version}.gem " \
          "(skipped; no gem was built in dry-run mode)"
      )
      expect(output).to include(
        "[dry-run] gem push sub_gem-#{next_version}.gem " \
          "(skipped; no gem was built in dry-run mode)"
      )

      in_project do
        expect(read_ruby_gem_version_file).to have_ruby_version(next_version)
        changelog = read_changelog_file
        expect_changelog_to_include_version_header(changelog, next_version)
        expect_changelog_to_include_release_notes(changelog, :minor)

        in_package :sub_gem do
          expect(read_ruby_gem_version_file).to have_ruby_version(next_version)
          changelog = read_changelog_file
          expect_changelog_to_include_version_header(changelog, next_version)
        end

        # No release commit is created, so the updated files stay uncommitted.
        expect(local_changes?).to be_truthy
      end

      # Every package is built and pushed together under one shared tag, so the
      # plan lists a `gem build` per package but only one tag and one tag push.
      # The `gem push` commands are absent because no gems were built.
      expect(performed_commands).to eql([
        [project_dir, "git tag --list #{tag}"],
        [project_dir, "gem build"],
        [sub_gem_dir, "gem build"],
        [project_dir, "git add -A"],
        [
          project_dir,
          "git commit -m 'Publish version #{tag}' " \
            "-m 'Update version number and CHANGELOG.md.\n\n" \
            "- root_gem\n- sub_gem'"
        ],
        [project_dir, version_tag_command(tag, "tmp/v1-3-0_changesets.txt")],
        [project_dir, "git push origin main"],
        [project_dir, "git push origin #{tag}"]
      ])
      expect(exit_status).to eql(0), output
    end
  end
end
