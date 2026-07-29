# frozen_string_literal: true

RSpec.describe Mono::Cli::Publish do
  include PublishHelper

  around { |example| with_mock_stdin { example.run } }

  context "with version_lock and a packages map" do
    it "releases every package together at one shared version" do
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
      output = run_publish(:lang => :ruby)

      project_dir = current_project_path
      sub_gem_dir = "#{project_dir}/packages/sub_gem"
      next_version = "1.3.0"
      tag = "v#{next_version}"

      expect(output).to has_publish_and_update_summary(
        :root_gem => {
          :old => "v1.2.3", :new => "v1.3.0", :bump => :minor
        },
        :sub_gem => {
          :old => "v1.2.3", :new => "v1.3.0", :bump => :minor
        }
      )

      in_project do
        # The root package reads and writes its files at the repository root.
        expect(read_ruby_gem_version_file).to have_ruby_version(next_version)
        changelog = read_changelog_file
        expect_changelog_to_include_version_header(changelog, next_version)
        expect_changelog_to_include_release_notes(changelog, :minor)

        # The package without changes of its own is released only to keep the
        # version in step, and its changelog says so.
        in_package :sub_gem do
          expect(read_ruby_gem_version_file).to have_ruby_version(next_version)
          changelog = read_changelog_file
          expect_changelog_to_include_version_header(changelog, next_version)
          expect(changelog).to include(
            "Released to keep the version in step with root_gem #{next_version}."
          )
        end

        expect(local_changes?).to be_falsy, local_changes.inspect
        expect(commited_files).to eql([
          ".changesets/1_minor.md",
          "CHANGELOG.md",
          "lib/example/version.rb",
          "packages/sub_gem/CHANGELOG.md",
          "packages/sub_gem/lib/example/version.rb"
        ])
      end

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
        [project_dir, "gem push ./root_gem-#{next_version}.gem"],
        [project_dir, "gem push packages/sub_gem/sub_gem-#{next_version}.gem"],
        [project_dir, "git push origin main"],
        [project_dir, "git push origin #{tag}"]
      ])
      expect(exit_status).to eql(0), output
    end

    it "exits with an error when combined with a package selection" do
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
      output = run_publish(["--package", "root_gem"], :lang => :ruby)

      expect(output).to include(
        "The `version_lock` option releases every package in the repository " \
          "together, so a `--package` selection cannot be used with it."
      )
      expect(performed_commands).to be_empty
      expect(exit_status).to eql(1), output
    end
  end
end
