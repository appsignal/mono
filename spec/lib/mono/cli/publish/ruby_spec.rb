# frozen_string_literal: true

RSpec.describe Mono::Cli::Publish do
  include PublishHelper

  around { |example| with_mock_stdin { example.run } }

  context "with single Ruby package" do
    it "publishes the package" do
      prepare_ruby_project do
        create_ruby_package_files :name => "mygem", :version => "1.2.3"
        add_changeset :patch
      end
      confirm_publish_package
      output = run_publish(:lang => :ruby)

      project_dir = current_project_path
      next_version = "1.2.4"
      tag = "v#{next_version}"

      expect(output).to has_publish_and_update_summary(
        current_project => { :old => "v1.2.3", :new => "v1.2.4", :bump => :patch }
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
        [project_dir, "git tag --list #{tag}"],
        [project_dir, "gem build"],
        [project_dir, "git add -A"],
        [
          project_dir,
          "git commit -m 'Publish package #{tag}' " \
            "-m 'Update version number and CHANGELOG.md.'"
        ],
        [project_dir, version_tag_command(tag)],
        [project_dir, "gem push mygem-#{next_version}.gem"],
        [project_dir, "git push origin main #{tag}"]
      ])
      expect(exit_status).to eql(0), output
    end

    context "with multiple .gem files" do
      it "only publishes this version's gemfiles" do
        prepare_ruby_project do
          create_ruby_package_files :name => "mygem", :version => "1.2.3"
          add_changeset :patch
          FileUtils.touch("mygem-1.2.3.gem")
          FileUtils.touch("mygem-1.2.4-java.gem")
        end
        confirm_publish_package
        output = run_publish(:lang => :ruby)

        project_dir = current_project_path
        next_version = "1.2.4"
        tag = "v#{next_version}"

        expect(output).to has_publish_and_update_summary(
          current_project => { :old => "v1.2.3", :new => "v1.2.4", :bump => :patch }
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
          [project_dir, "git tag --list #{tag}"],
          [project_dir, "gem build"],
          [project_dir, "git add -A"],
          [
            project_dir,
            "git commit -m 'Publish package #{tag}' " \
              "-m 'Update version number and CHANGELOG.md.'"
          ],
          [project_dir, version_tag_command(tag)],
          [project_dir, "gem push mygem-#{next_version}.gem"],
          [project_dir, "gem push mygem-#{next_version}-java.gem"],
          [project_dir, "git push origin main #{tag}"]
        ])
        expect(exit_status).to eql(0), output
      end
    end

    it "publishes the package without gemspec" do
      prepare_ruby_project do
        create_ruby_package_files :name => "mygem", :version => "1.2.3"
        configure_command "build", "echo build"
        configure_command "publish", "echo push"
        FileUtils.rm "mygem.gemspec"
        add_changeset :patch
      end
      confirm_publish_package
      output = run_publish(:lang => :ruby)

      project_dir = current_project_path
      next_version = "1.2.4"
      tag = "v#{next_version}"

      expect(output).to has_publish_and_update_summary(
        current_project => { :old => "v1.2.3", :new => "v1.2.4", :bump => :patch }
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
        [project_dir, "git tag --list #{tag}"],
        [project_dir, "echo build"],
        [project_dir, "git add -A"],
        [
          project_dir,
          "git commit -m 'Publish package #{tag}' " \
            "-m 'Update version number and CHANGELOG.md.'"
        ],
        [project_dir, version_tag_command(tag)],
        [project_dir, "echo push"],
        [project_dir, "git push origin main #{tag}"]
      ])
      expect(exit_status).to eql(0), output
    end
  end

  context "with mono Ruby package" do
    it "publishes the updated package" do
      prepare_ruby_project "packages_dir" => "packages/" do
        create_package :package_a do
          create_ruby_package_files :name => "package_a", :version => "1.2.3"
          add_changeset :patch
        end
        create_package :package_b do
          create_ruby_package_files :name => "package_b", :version => "2.0.0"
        end
      end
      confirm_publish_package
      output = run_publish(:lang => :ruby)

      project_dir = current_project_path
      package_dir_a = "#{project_dir}/packages/package_a"
      next_version_a = "1.2.4"
      tag_a = "package_a@#{next_version_a}"

      expect(output).to has_publish_and_update_summary(
        :package_a => { :old => "package_a@1.2.3", :new => "package_a@1.2.4", :bump => :patch },
        :package_b => :no_publish
      )

      in_project do
        in_package :package_a do
          expect(read_ruby_gem_version_file).to have_ruby_version(next_version_a)
          expect(current_package_changeset_files.length).to eql(0)

          changelog = read_changelog_file
          expect_changelog_to_include_version_header(changelog, next_version_a)
          expect_changelog_to_include_release_notes(changelog, :patch)
        end

        expect(local_changes?).to be_falsy, local_changes.inspect
        expect(commited_files).to eql([
          "packages/package_a/.changesets/1_patch.md",
          "packages/package_a/CHANGELOG.md",
          "packages/package_a/lib/example/version.rb"
        ])
      end

      expect(performed_commands).to eql([
        [project_dir, "git tag --list #{tag_a}"],
        [package_dir_a, "gem build"],
        [project_dir, "git add -A"],
        [
          project_dir,
          "git commit -m 'Publish package #{tag_a}' " \
            "-m 'Update version number and CHANGELOG.md.'"
        ],
        [project_dir, version_tag_command(tag_a, tmp_changelog_file_for("package_a"))],
        [project_dir, "gem push packages/package_a/package_a-#{next_version_a}.gem"],
        [project_dir, "git push origin main #{tag_a}"]
      ])
      expect(exit_status).to eql(0), output
    end

    it "publishes multiple updated packages" do
      prepare_ruby_project "packages_dir" => "packages/" do
        create_package :package_a do
          create_ruby_package_files :name => "package_a", :version => "1.2.3"
          add_changeset :patch
        end
        create_package :package_b do
          create_ruby_package_files :name => "package_b", :version => "2.0.0"
          add_changeset :patch
        end
      end
      confirm_publish_package
      output = run_publish(:lang => :ruby)

      project_dir = current_project_path
      package_dir_a = "#{project_dir}/packages/package_a"
      package_dir_b = "#{project_dir}/packages/package_b"
      next_version_a = "1.2.4"
      next_version_b = "2.0.1"
      tag_a = "package_a@#{next_version_a}"
      tag_b = "package_b@#{next_version_b}"

      expect(output).to has_publish_and_update_summary(
        :package_a => { :old => "package_a@1.2.3", :new => "package_a@1.2.4", :bump => :patch },
        :package_b => { :old => "package_b@2.0.0", :new => "package_b@2.0.1", :bump => :patch }
      )

      in_project do
        in_package :package_a do
          expect(read_ruby_gem_version_file).to have_ruby_version(next_version_a)
          expect(current_package_changeset_files.length).to eql(0)

          changelog = read_changelog_file
          expect_changelog_to_include_version_header(changelog, next_version_a)
          expect_changelog_to_include_release_notes(changelog, :patch)
        end

        in_package :package_b do
          expect(read_ruby_gem_version_file).to have_ruby_version(next_version_b)
          expect(current_package_changeset_files.length).to eql(0)

          changelog = read_changelog_file
          expect_changelog_to_include_version_header(changelog, next_version_b)
          expect_changelog_to_include_release_notes(changelog, :patch)
        end

        expect(local_changes?).to be_falsy, local_changes.inspect
        expect(commited_files).to eql([
          "packages/package_a/.changesets/1_patch.md",
          "packages/package_a/CHANGELOG.md",
          "packages/package_a/lib/example/version.rb",
          "packages/package_b/.changesets/2_patch.md",
          "packages/package_b/CHANGELOG.md",
          "packages/package_b/lib/example/version.rb"
        ])
      end

      expect(performed_commands).to eql([
        [project_dir, "git tag --list #{tag_a} #{tag_b}"],
        [package_dir_a, "gem build"],
        [package_dir_b, "gem build"],
        [project_dir, "git add -A"],
        [
          project_dir,
          "git commit -m 'Publish packages' " \
            "-m 'Update version number and CHANGELOG.md.\n\n- #{tag_a}\n- #{tag_b}'"
        ],
        [project_dir, version_tag_command(tag_a, tmp_changelog_file_for("package_a"))],
        [project_dir, version_tag_command(tag_b, tmp_changelog_file_for("package_b"))],
        [project_dir, "gem push packages/package_a/package_a-#{next_version_a}.gem"],
        [project_dir, "gem push packages/package_b/package_b-#{next_version_b}.gem"],
        [project_dir, "git push origin main #{tag_a} #{tag_b}"]
      ])
      expect(exit_status).to eql(0), output
    end

    it "publishes dependent packages" do
      prepare_ruby_project "packages_dir" => "packages/" do
        create_package :package_a do
          create_ruby_package_files :name => "package_a", :version => "1.2.3"
          add_changeset :patch
        end
        create_package :package_b do
          create_ruby_package_files :name => "package_b",
            :version => "2.0.0",
            :dependencies => { "package_a" => "1.2.3" }
        end
        create_package :package_c do
          create_ruby_package_files :name => "package_c",
            :version => "3.3.0",
            :dependencies => { "package_b" => "2.0.0" }
        end
      end
      confirm_publish_package
      output = run_publish(:lang => :ruby)

      project_dir = current_project_path
      package_dir_a = "#{project_dir}/packages/package_a"
      package_dir_b = "#{project_dir}/packages/package_b"
      package_dir_c = "#{project_dir}/packages/package_c"
      next_version_a = "1.2.4"
      next_version_b = "2.0.1"
      next_version_c = "3.3.1"
      tag_a = "package_a@#{next_version_a}"
      tag_b = "package_b@#{next_version_b}"
      tag_c = "package_c@#{next_version_c}"

      expect(output).to has_publish_and_update_summary(
        :package_a => { :old => "package_a@1.2.3", :new => "package_a@1.2.4", :bump => :patch },
        :package_b => { :old => "package_b@2.0.0", :new => "package_b@2.0.1", :bump => :patch },
        :package_c => { :old => "package_c@3.3.0", :new => "package_c@3.3.1", :bump => :patch }
      )

      in_project do
        in_package :package_a do
          expect(read_ruby_gem_version_file).to have_ruby_version(next_version_a)
          expect(current_package_changeset_files.length).to eql(0)

          changelog = read_changelog_file
          expect_changelog_to_include_version_header(changelog, next_version_a)
          expect_changelog_to_include_release_notes(changelog, :patch)
        end

        in_package :package_b do
          expect(read_ruby_gem_version_file).to have_ruby_version(next_version_b)
          expect(current_package_changeset_files.length).to eql(0)

          changelog = read_changelog_file
          expect_changelog_to_include_version_header(changelog, next_version_b)
          expect_changelog_to_include_package_bump(changelog, "package_a", next_version_a)
        end

        in_package :package_c do
          expect(read_ruby_gem_version_file).to have_ruby_version(next_version_c)
          expect(current_package_changeset_files.length).to eql(0)

          changelog = read_changelog_file
          expect_changelog_to_include_version_header(changelog, next_version_c)
          expect_changelog_to_include_package_bump(changelog, "package_b", next_version_b)
        end

        expect(local_changes?).to be_falsy, local_changes.inspect
        expect(commited_files).to eql([
          "packages/package_a/.changesets/1_patch.md",
          "packages/package_a/CHANGELOG.md",
          "packages/package_a/lib/example/version.rb",
          "packages/package_b/CHANGELOG.md",
          "packages/package_b/lib/example/version.rb",
          "packages/package_b/package_b.gemspec",
          "packages/package_c/CHANGELOG.md",
          "packages/package_c/lib/example/version.rb",
          "packages/package_c/package_c.gemspec"
        ])
      end

      expect(performed_commands).to eql([
        [project_dir, "git tag --list #{tag_a} #{tag_b} #{tag_c}"],
        [package_dir_a, "gem build"],
        [package_dir_b, "gem build"],
        [package_dir_c, "gem build"],
        [project_dir, "git add -A"],
        [
          project_dir,
          "git commit -m 'Publish packages' " \
            "-m 'Update version number and CHANGELOG.md.\n\n- #{tag_a}\n- #{tag_b}\n- #{tag_c}'"
        ],
        [project_dir, version_tag_command(tag_a, tmp_changelog_file_for("package_a"))],
        [project_dir, version_tag_command(tag_b, tmp_changelog_file_for("package_b"))],
        [project_dir, version_tag_command(tag_c, tmp_changelog_file_for("package_c"))],
        [project_dir, "gem push packages/package_a/package_a-#{next_version_a}.gem"],
        [project_dir, "gem push packages/package_b/package_b-#{next_version_b}.gem"],
        [project_dir, "gem push packages/package_c/package_c-#{next_version_c}.gem"],
        [project_dir, "git push origin main #{tag_a} #{tag_b} #{tag_c}"]
      ])
      expect(exit_status).to eql(0), output
    end
  end
end
