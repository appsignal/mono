# frozen_string_literal: true

RSpec.describe Mono::Cli::Publish do
  include PublishHelper

  around { |example| with_mock_stdin { example.run } }

  it "publishes the package" do
    mono_config = {
      "build" => { "command" => "echo build" },
      "publish" => { "command" => "echo publish" },
      "read_version" => "cat version.py",
      "write_version" => "ruby write_version_file.rb",
      "version_scheme" => "python"
    }
    prepare_custom_project mono_config do
      create_version_file "1.2.3a1"
      File.write("write_version_file.rb", %(File.write("version.py", ARGV[0])))
      add_changeset :patch
    end
    confirm_publish_package
    output = run_publish(["--alpha"], :lang => :custom)

    project_dir = "/#{current_project}"
    next_version = "1.2.3a2"

    expect(output).to has_publish_and_update_summary(
      current_project => { :old => "v1.2.3a1", :new => "v1.2.3a2", :bump => :patch }
    )

    in_project do
      expect(File.read("version.py")).to include(next_version)
      expect(current_package_changeset_files.length).to eql(0)

      changelog = read_changelog_file
      expect_changelog_to_include_version_header(changelog, next_version)
      expect_changelog_to_include_release_notes(changelog, :patch)

      expect(local_changes?).to be_falsy, local_changes.inspect
      expect(commited_files).to eql([
        ".changesets/1_patch.md",
        "CHANGELOG.md",
        "version.py"
      ])
    end

    expect(performed_commands).to eql([
      [project_dir, "cat version.py"],
      [project_dir, "git tag --list v#{next_version}"],
      [project_dir, "ruby write_version_file.rb #{next_version}"],
      [project_dir, "echo build"],
      [project_dir, "git add -A"],
      [
        project_dir,
        "git commit -m 'Publish package v#{next_version}' " \
          "-m 'Update version number and CHANGELOG.md.'"
      ],
      [project_dir, "git tag v#{next_version}"],
      [project_dir, "echo publish"],
      [project_dir, "git push origin main v#{next_version}"]
    ])
    expect(exit_status).to eql(0), output
  end

  def prepare_custom_project(config = {})
    prepare_new_project do
      create_mono_config({ "language" => "custom" }.merge(config))
      yield
    end
  end

  def create_version_file(version)
    File.write("version.py", version)
  end
end
