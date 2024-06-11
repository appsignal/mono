# frozen_string_literal: true

RSpec.describe Mono::Cli::Publish do
  include PublishHelper

  around { |example| with_mock_stdin { example.run } }

  context "with single Elixir package" do
    it "publishes the package" do
      prepare_elixir_project do
        create_package_mix :version => "1.2.3"
        add_changeset :patch
      end
      confirm_publish_package
      output = run_publish(:lang => :elixir)

      project_dir = current_project_path
      next_version = "1.2.4"
      tag = "v#{next_version}"

      expect(output).to has_publish_and_update_summary(
        current_project => { :old => "v1.2.3", :new => "v1.2.4", :bump => :patch }
      )

      in_project do
        expect(File.read("mix.exs")).to include(%(version: "#{next_version}",))
        expect(current_package_changeset_files.length).to eql(0)

        changelog = read_changelog_file
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
        [project_dir, "git tag --list #{tag}"],
        [project_dir, "mix compile"],
        [project_dir, "git add -A"],
        [
          project_dir,
          "git commit -m 'Publish package v#{next_version}' " \
            "-m 'Update version number and CHANGELOG.md.'"
        ],
        [project_dir, version_tag_command(tag)],
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
        add_changeset :patch
      end
      confirm_publish_package
      output = run_publish(:lang => :elixir)

      project_dir = current_project_path
      next_version = "1.2.4"
      tag = "v#{next_version}"

      expect(output).to has_publish_and_update_summary(
        current_project => { :old => "v1.2.3", :new => "v1.2.4", :bump => :patch }
      )

      in_project do
        contents = File.read("mix.exs")
        expect(contents).to include(%(@version "#{next_version}"))
        expect(contents).to include(%(version: @version,))
        expect(current_package_changeset_files.length).to eql(0)

        changelog = read_changelog_file
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
        [project_dir, "git tag --list #{tag}"],
        [project_dir, "mix compile"],
        [project_dir, "git add -A"],
        [
          project_dir,
          "git commit -m 'Publish package #{tag}' " \
            "-m 'Update version number and CHANGELOG.md.'"
        ],
        [project_dir, version_tag_command(tag)],
        [project_dir, "mix hex.publish package --yes"],
        [project_dir, "git push origin main #{tag}"]
      ])
      expect(exit_status).to eql(0), output
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
      output = run_publish(:lang => :elixir)

      project_dir = current_project_path
      package_dir_a = "#{project_dir}/packages/package_a"
      package_dir_b = "#{project_dir}/packages/package_b"
      next_version_a = "1.2.4"
      tag = "package_a@#{next_version_a}"

      expect(output).to has_publish_and_update_summary(
        :package_a => { :old => "package_a@1.2.3", :new => "package_a@1.2.4", :bump => :patch },
        :package_b => :no_publish
      )

      in_project do
        in_package :package_a do
          expect(File.read("mix.exs")).to include(%(version: "#{next_version_a}",))
          expect(current_package_changeset_files.length).to eql(0)

          changelog = read_changelog_file
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
        [project_dir, version_tag_command(tag, tmp_changelog_file_for("package_a"))],
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
      output = run_publish(:lang => :elixir)

      project_dir = current_project_path
      package_dir_a = "#{project_dir}/packages/jason"
      package_dir_b = "#{project_dir}/packages/package_b"
      next_version_a = "1.1.3"
      next_version_b = "2.0.1"
      tag_a = "jason@#{next_version_a}"
      tag_b = "package_b@#{next_version_b}"

      expect(output).to has_publish_and_update_summary(
        :jason => { :old => "jason@1.1.2", :new => "jason@1.1.3", :bump => :patch },
        :package_b => { :old => "package_b@2.0.0", :new => "package_b@2.0.1", :bump => :patch }
      )

      in_project do
        in_package :jason do
          expect(File.read("mix.exs")).to include(%(version: "#{next_version_a}",))
          expect(current_package_changeset_files.length).to eql(0)

          changelog = read_changelog_file
          expect_changelog_to_include_version_header(changelog, next_version_a)
          expect_changelog_to_include_release_notes(changelog, :patch)
        end

        in_package :package_b do
          expect(File.read("mix.exs")).to include(%(version: "#{next_version_b}",))
          expect(current_package_changeset_files.length).to eql(0)

          changelog = read_changelog_file
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
        [project_dir, version_tag_command(tag_a, tmp_changelog_file_for("jason"))],
        [project_dir, version_tag_command(tag_b, tmp_changelog_file_for("package_b"))],
        [package_dir_a, "mix hex.publish package --yes"],
        [package_dir_b, "mix hex.publish package --yes"],
        [project_dir, "git push origin main #{tag_a} #{tag_b}"]
      ])
      expect(exit_status).to eql(0), output
    end
  end
end
