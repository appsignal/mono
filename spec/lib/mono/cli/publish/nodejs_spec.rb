# frozen_string_literal: true

RSpec.describe Mono::Cli::Publish do
  include PublishHelper

  around { |example| with_mock_stdin { example.run } }

  context "with mono Node.js project" do
    it "publishes the updated package" do
      prepare_project :nodejs_npm_mono
      confirm_publish_package
      output =
        capture_stdout do
          in_project do
            in_package "package_one" do
              add_changeset(:patch)
            end

            perform_commands do
              stub_commands [/^npm publish/, /^git push/] do
                run_bootstrap
                run_publish
              end
            end
          end
        end

      project_dir = "/nodejs_npm_mono_project"
      package_one_dir = "#{project_dir}/packages/package_one"
      package_two_dir = "#{project_dir}/packages/package_two"
      next_version = "1.2.4"
      tag = "package_one@#{next_version}"

      expect(output).to include(<<~OUTPUT), output
        The following packages will be published (or not):
        - package_one:
          Current version: package_one@1.2.3
          Next version:    package_one@1.2.4 (patch)
        - package_two: (Will not publish)
      OUTPUT
      expect(output).to include(<<~OUTPUT), output
        # Updating package versions
        - package_one:
          Current version: package_one@1.2.3
          Next version:    package_one@1.2.4 (patch)
      OUTPUT

      in_project do
        in_package "package_one" do
          expect(File.read("package.json")).to include(%("version": "#{next_version}"))

          changelog = File.read("CHANGELOG.md")
          expect_changelog_to_include_version_header(changelog, next_version)
          expect_changelog_to_include_release_notes(changelog, :patch)
        end

        expect(local_changes?).to be_falsy, local_changes.inspect
        expect(commited_files).to eql([
          "packages/package_one/.changesets/1_patch.md",
          "packages/package_one/CHANGELOG.md",
          "packages/package_one/constants.js",
          "packages/package_one/package.json"
        ])
      end

      expect(performed_commands).to eql([
        [project_dir, "npm install"],
        [package_one_dir, "npm link"],
        [package_two_dir, "npm link"],
        [project_dir, "npm run build --workspace=package_one"],
        [project_dir, "git add -A"],
        [project_dir, "git commit -m 'Publish packages [ci skip]' -m '- #{tag}'"],
        [project_dir, "git tag #{tag}"],
        [project_dir, "npm publish --workspace=package_one"],
        [project_dir, "git push origin main #{tag}"]
      ])
      expect(exit_status).to eql(0), output
    end

    it "publishes multiple packages" do
      prepare_project :nodejs_npm_mono
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
              stub_commands [/^npm publish/, /^git push/] do
                run_bootstrap
                run_publish
              end
            end
          end
        end

      project_dir = "/nodejs_npm_mono_project"
      package_one_dir = "#{project_dir}/packages/package_one"
      package_two_dir = "#{project_dir}/packages/package_two"
      next_version = "1.2.4"
      package_one_tag = "package_one@#{next_version}"
      package_two_tag = "package_two@#{next_version}"

      expect(output).to include(<<~OUTPUT), output
        The following packages will be published (or not):
        - package_one:
          Current version: package_one@1.2.3
          Next version:    package_one@1.2.4 (patch)
        - package_two:
          Current version: package_two@1.2.3
          Next version:    package_two@1.2.4 (patch)
      OUTPUT
      expect(output).to include(<<~OUTPUT), output
        # Updating package versions
        - package_one:
          Current version: package_one@1.2.3
          Next version:    package_one@1.2.4 (patch)
        - package_two:
          Current version: package_two@1.2.3
          Next version:    package_two@1.2.4 (patch)
      OUTPUT

      in_project do
        in_package "package_one" do
          expect(File.read("package.json")).to include(%("version": "#{next_version}"))

          changelog = File.read("CHANGELOG.md")
          expect_changelog_to_include_version_header(changelog, next_version)
          expect_changelog_to_include_release_notes(changelog, :patch)
        end

        in_package "package_two" do
          package_json = JSON.parse(File.read("package.json"))
          expect(package_json["version"]).to include(next_version)

          changelog = File.read("CHANGELOG.md")
          expect_changelog_to_include_version_header(changelog, next_version)
          expect_changelog_to_include_release_notes(changelog, :patch)
        end

        expect(local_changes?).to be_falsy, local_changes.inspect
        expect(commited_files).to eql([
          "packages/package_one/.changesets/1_patch.md",
          "packages/package_one/CHANGELOG.md",
          "packages/package_one/constants.js",
          "packages/package_one/package.json",
          "packages/package_two/.changesets/2_patch.md",
          "packages/package_two/CHANGELOG.md",
          "packages/package_two/package.json"
        ])
      end

      commit_message = "- #{package_one_tag}\n- #{package_two_tag}"
      expect(performed_commands).to eql([
        [project_dir, "npm install"],
        [package_one_dir, "npm link"],
        [package_two_dir, "npm link"],
        [project_dir, "npm run build --workspace=package_one"],
        [project_dir, "npm run build --workspace=package_two"],
        [project_dir, "git add -A"],
        [project_dir, "git commit -m 'Publish packages [ci skip]' -m '#{commit_message}'"],
        [project_dir, "git tag #{package_one_tag}"],
        [project_dir, "git tag #{package_two_tag}"],
        [project_dir, "npm publish --workspace=package_one"],
        [project_dir, "npm publish --workspace=package_two"],
        [project_dir, "git push origin main #{package_one_tag} #{package_two_tag}"]
      ])
      expect(exit_status).to eql(0), output
    end
  end
end
