# frozen_string_literal: true

RSpec.describe Mono::Cli::Publish do
  include PublishHelper

  around { |example| with_mock_stdin { example.run } }

  it "publishes the package" do
    mono_config = {
      "build" => { "command" => "echo build" },
      "publish" => { "command" => "echo publish" },
      "read_version" => "cat version.py",
      "write_version" => "ruby write_version_file.rb"
    }
    prepare_custom_project mono_config do
      create_version_file "1.2.3"
      File.write("write_version_file.rb", %(File.write("version.py", ARGV[0])))
      add_changeset :patch
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
      expect(File.read("version.py")).to include(next_version)
      expect(current_package_changeset_files.length).to eql(0)

      changelog = File.read("CHANGELOG.md")
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
      [project_dir, "ruby write_version_file.rb #{next_version}"],
      [project_dir, "echo build"],
      [project_dir, "git add -A"],
      [project_dir, "git commit -m 'Publish packages' -m '- v#{next_version}'"],
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

  def run_publish_process(failed_commands: [], stubbed_commands: [/^git push/])
    output =
      capture_stdout do
        in_project do
          perform_commands do
            fail_commands failed_commands do
              stub_commands stubbed_commands do
                run_publish
              end
            end
          end
        end
      end
    strip_changeset_output output
  end
end
