# frozen_string_literal: true

RSpec.describe Mono::Cli::Publish do
  include PublishHelper

  around { |example| with_mock_stdin { example.run } }

  context "with single Ruby package" do
    it "publishes the package" do
      prepare_project :ruby_single
      confirm_publish_package
      output =
        capture_stdout do
          in_project do
            add_changeset(:patch)

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

    context "with multiple .gem files" do
      it "only publishes this version's gemfiles" do
        prepare_project :ruby_single
        confirm_publish_package
        output =
          capture_stdout do
            in_project do
              FileUtils.touch("ruby_single_project-1.2.3.gem")
              FileUtils.touch("ruby_single_project-1.2.4-java.gem")
              add_changeset(:patch)

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
          [project_dir, "gem push ruby_single_project-#{next_version}-java.gem"],
          [project_dir, "git push origin main v#{next_version}"]
        ])
        expect(exit_status).to eql(0), output
      end
    end
  end

  pending "Ruby mono project (optional: for non Appsignal projects)"
end
