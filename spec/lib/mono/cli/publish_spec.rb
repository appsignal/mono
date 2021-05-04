# frozen_string_literal: true

RSpec.describe Mono::Cli::Publish do
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

  context "with changes in the package" do
    context "with uncommitted changes" do
      it "exits with an error" do
        prepare_project :ruby_single
        output =
          capture_stdout do
            in_project do
              add_changeset(:patch)
              `touch uncommited_file`
              run_publish
            end
          end

        expect(performed_commands).to be_empty
        expect(output).to include("Error: There are local changes before building.")
        expect(exit_status).to eql(1), output
      end
    end

    context "with single Ruby package" do
      it "publishes the package" do
        prepare_project :ruby_single
        output =
          capture_stdout do
            in_project do
              add_changeset(:patch)
              expect(current_package_changeset_files.length).to eql(1)

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
          expect(File.read("lib/appsignal/version.rb")).to include(%(VERSION = "#{next_version}"))
          expect(Dir.glob(".changesets/*.md").length).to eql(0)

          changelog = File.read("CHANGELOG.md")
          expect_changelog_to_include_version_header(changelog, next_version)
          expect_changelog_to_include_release_notes(changelog, :patch)

          expect(local_changes?).to be_falsy, local_changes.inspect
          expect(commited_files).to eql([
            ".changesets/1_patch.md",
            "CHANGELOG.md",
            "lib/appsignal/version.rb"
          ])
        end

        expect(performed_commands).to eql([
          [project_dir, "gem build"],
          [project_dir, "git commit -am 'Publish packages [ci skip]' -m '- v#{next_version}'"],
          [project_dir, "git tag v#{next_version}"],
          [project_dir, "gem push ruby_single_project-#{next_version}.gem"],
          [project_dir, "git push origin main v#{next_version}"]
        ])
        expect(exit_status).to eql(0), output
      end

      context "with --alpha option" do
        it "publishes an alpha prerelease" do
          prepare_project :ruby_single
          output =
            capture_stdout do
              in_project do
                add_changeset(:patch)
                expect(current_package_changeset_files.length).to eql(1)

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
            expect(File.read("lib/appsignal/version.rb")).to include(%(VERSION = "#{next_version}"))
            expect(Dir.glob(".changesets/*.md").length).to eql(0)

            changelog = File.read("CHANGELOG.md")
            expect_changelog_to_include_version_header(changelog, next_version)
            expect_changelog_to_include_release_notes(changelog, :patch)

            expect(local_changes?).to be_falsy, local_changes.inspect
            expect(commited_files).to eql([
              ".changesets/1_patch.md",
              "CHANGELOG.md",
              "lib/appsignal/version.rb"
            ])
          end

          expect(performed_commands).to eql([
            [project_dir, "gem build"],
            [project_dir, "git commit -am 'Publish packages [ci skip]' -m '- v#{next_version}'"],
            [project_dir, "git tag v#{next_version}"],
            [project_dir, "gem push ruby_single_project-#{next_version}.gem"],
            [project_dir, "git push origin main v#{next_version}"]
          ])
          expect(exit_status).to eql(0), output
        end
      end
    end

    context "with single Elixir package" do
      it "publishes the package" do
        prepare_project :elixir_single
        output =
          capture_stdout do
            in_project do
              add_changeset(:patch)
              expect(current_package_changeset_files.length).to eql(1)

              perform_commands do
                stub_commands [/^mix hex.publish package --yes/, /^git push/] do
                  run_bootstrap
                  run_publish
                end
              end
            end
          end

        project_dir = "/elixir_single_project"
        next_version = "1.2.4"

        expect(output).to include(<<~OUTPUT), output
          The following packages will be published (or not):
          - elixir_single_project:
            Current version: v1.2.3
            Next version:    v1.2.4 (patch)
        OUTPUT
        expect(output).to include(<<~OUTPUT), output
          # Updating package versions
          - elixir_single_project:
            Current version: v1.2.3
            Next version:    v1.2.4 (patch)
        OUTPUT

        in_project do
          expect(File.read("mix.exs")).to include(%(@version "#{next_version}"))
          expect(Dir.glob(".changesets/*.md").length).to eql(0)

          changelog = File.read("CHANGELOG.md")
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
          [project_dir, "mix compile"],
          [project_dir, "git commit -am 'Publish packages [ci skip]' -m '- v#{next_version}'"],
          [project_dir, "git tag v#{next_version}"],
          [project_dir, "mix hex.publish package --yes"],
          [project_dir, "git push origin main v#{next_version}"]
        ])
        expect(exit_status).to eql(0), output
      end
    end

    context "with mono Elixir project" do
      it "publishes the package" do
        prepare_project :elixir_mono
        output =
          capture_stdout do
            in_project do
              in_package "package_one" do
                add_changeset(:patch)
                expect(current_package_changeset_files.length).to eql(1)
              end

              perform_commands do
                stub_commands [/^mix hex.publish package --yes/, /^git push/] do
                  run_bootstrap
                  run_publish
                end
              end
            end
          end

        project_dir = "/elixir_mono_project"
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
            expect(File.read("mix.exs")).to include(%(@version "#{next_version}"))
            expect(Dir.glob(".changesets/*.md").length).to eql(0)

            changelog = File.read("CHANGELOG.md")
            expect_changelog_to_include_version_header(changelog, next_version)
            expect_changelog_to_include_release_notes(changelog, :patch)
          end

          expect(local_changes?).to be_falsy, local_changes.inspect
          expect(commited_files).to eql([
            "packages/package_one/.changesets/1_patch.md",
            "packages/package_one/CHANGELOG.md",
            "packages/package_one/mix.exs"
          ])
        end

        expect(performed_commands).to eql([
          [package_one_dir, "mix deps.get"],
          [package_two_dir, "mix deps.get"],
          [package_one_dir, "mix compile"],
          [project_dir, "git commit -am 'Publish packages [ci skip]' -m '- #{tag}'"],
          [project_dir, "git tag #{tag}"],
          [package_one_dir, "mix hex.publish package --yes"],
          [project_dir, "git push origin main #{tag}"]
        ])
        expect(exit_status).to eql(0), output
      end
    end

    context "with mono Node.js project" do
      it "publishes the package" do
        prepare_project :nodejs_npm_mono
        output =
          capture_stdout do
            in_project do
              in_package "package_one" do
                add_changeset(:patch)
                expect(current_package_changeset_files.length).to eql(1)
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
            expect(current_package_changeset_files.length).to eql(0)

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
          [package_one_dir, "npm run build"],
          [project_dir, "git commit -am 'Publish packages [ci skip]' -m '- #{tag}'"],
          [project_dir, "git tag #{tag}"],
          [package_one_dir, "npm publish"],
          [project_dir, "git push origin main #{tag}"]
        ])
        expect(exit_status).to eql(0), output
      end
    end

    pending "Ruby mono project (optional: for non Appsignal projects)"
    pending "Elixir mono project (for the future mono repo setup for Elixir)"
    pending "Node.js single project (optional: for non Appsignal projects)"
  end

  def expect_changelog_to_include_version_header(changelog, version)
    expect(changelog).to include("## #{version}")
  end

  def expect_changelog_to_include_release_notes(changelog, bump)
    url = "https://github.com/appsignal/#{selected_project}"
    message = "This is a #{bump} changeset bump."
    expect(changelog)
      .to match(%r{- \[[a-z0-9]{7}\]\(#{url}/commit/[a-z0-9]{40}\) #{bump} - #{message}})
  end

  def run_publish(args = {})
    Mono::Cli::Wrapper.new(:publish, args).execute
  end

  def run_bootstrap(args = {})
    Mono::Cli::Wrapper.new(:bootstrap, args).execute
  end
end
