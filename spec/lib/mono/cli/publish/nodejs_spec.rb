# frozen_string_literal: true

RSpec.describe Mono::Cli::Publish do
  include PublishHelper

  around { |example| with_mock_stdin { example.run } }

  context "with npm" do
    context "with single Node.js package" do
      it "publishes the updated package" do
        prepare_nodejs_project do
          create_package_json :name => "my_package", :version => "1.0.0"
          add_changeset :patch
        end
        confirm_publish_package
        output = run_publish(:lang => :nodejs)

        project_dir = current_project_path
        next_version = "1.0.1"
        tag = "v#{next_version}"

        expect(output).to has_publish_and_update_summary(
          :my_package => { :old => "v1.0.0", :new => "v1.0.1", :bump => :patch }
        )

        in_project do
          expect(File.read("package.json")).to include(%("version": "#{next_version}"))

          changelog = read_changelog_file
          expect_changelog_to_include_version_header(changelog, next_version)
          expect_changelog_to_include_release_notes(changelog, :patch)

          expect(local_changes?).to be_falsy, local_changes.inspect
          expect(commited_files).to eql([
            ".changesets/1_patch.md",
            "CHANGELOG.md",
            "package.json"
          ])
        end

        expect(performed_commands).to eql([
          [project_dir, "npm install"],
          [project_dir, "npm link"],
          [project_dir, "git tag --list #{tag}"],
          [project_dir, "npm run build"],
          [project_dir, "git add -A"],
          [
            project_dir,
            "git commit -m 'Publish package #{tag}' -m 'Update version number and CHANGELOG.md.'"
          ],
          [project_dir, "git tag #{tag}"],
          [project_dir, "npm publish"],
          [project_dir, "git push origin main #{tag}"]
        ])
        expect(exit_status).to eql(0), output
      end

      it "publishes the updated package as an alpha release" do
        prepare_nodejs_project do
          create_package_json :name => "my_package", :version => "1.0.0"
          add_changeset :patch
        end
        confirm_publish_package
        output = run_publish(["--alpha"], :lang => :nodejs)

        project_dir = current_project_path
        next_version = "1.0.1-alpha.1"
        tag = "v#{next_version}"

        expect(output).to has_publish_and_update_summary(
          :my_package => { :old => "v1.0.0", :new => "v1.0.1-alpha.1", :bump => :patch }
        )

        in_project do
          expect(File.read("package.json")).to include(%("version": "#{next_version}"))
        end

        expect(performed_commands).to eql([
          [project_dir, "npm install"],
          [project_dir, "npm link"],
          [project_dir, "git tag --list #{tag}"],
          [project_dir, "npm run build"],
          [project_dir, "git add -A"],
          [
            project_dir,
            "git commit -m 'Publish package #{tag}' -m 'Update version number and CHANGELOG.md.'"
          ],
          [project_dir, "git tag #{tag}"],
          [project_dir, "npm publish --tag alpha"],
          [project_dir, "git push origin main #{tag}"]
        ])
        expect(exit_status).to eql(0), output
      end

      it "publishes the updated package as a beta release" do
        prepare_nodejs_project do
          create_package_json :name => "my_package", :version => "1.0.0"
          add_changeset :patch
        end
        confirm_publish_package
        output = run_publish(["--beta"], :lang => :nodejs)

        project_dir = current_project_path
        next_version = "1.0.1-beta.1"
        tag = "v#{next_version}"

        expect(output).to has_publish_and_update_summary(
          :my_package => { :old => "v1.0.0", :new => "v1.0.1-beta.1", :bump => :patch }
        )

        in_project do
          expect(File.read("package.json")).to include(%("version": "#{next_version}"))
        end

        expect(performed_commands).to eql([
          [project_dir, "npm install"],
          [project_dir, "npm link"],
          [project_dir, "git tag --list #{tag}"],
          [project_dir, "npm run build"],
          [project_dir, "git add -A"],
          [
            project_dir,
            "git commit -m 'Publish package #{tag}' -m 'Update version number and CHANGELOG.md.'"
          ],
          [project_dir, "git tag #{tag}"],
          [project_dir, "npm publish --tag beta"],
          [project_dir, "git push origin main #{tag}"]
        ])
        expect(exit_status).to eql(0), output
      end

      it "publishes the updated package with a custom tag" do
        prepare_nodejs_project do
          create_package_json :name => "my_package", :version => "2.3.1"
          add_changeset :patch
        end
        confirm_publish_package
        package_tag = "2.x-stable"
        output = run_publish(["--tag", package_tag], :lang => :nodejs)

        project_dir = current_project_path
        next_version = "2.3.2"
        tag = "v#{next_version}"

        expect(output).to has_publish_and_update_summary(
          :my_package => { :old => "v2.3.1", :new => "v2.3.2", :bump => :patch }
        )

        in_project do
          expect(File.read("package.json")).to include(%("version": "#{next_version}"))
        end

        expect(performed_commands).to eql([
          [project_dir, "npm install"],
          [project_dir, "npm link"],
          [project_dir, "git tag --list #{tag}"],
          [project_dir, "npm run build"],
          [project_dir, "git add -A"],
          [
            project_dir,
            "git commit -m 'Publish package #{tag}' -m 'Update version number and CHANGELOG.md.'"
          ],
          [project_dir, "git tag #{tag}"],
          [project_dir, "npm publish --tag #{package_tag}"],
          [project_dir, "git push origin main #{tag}"]
        ])
        expect(exit_status).to eql(0), output
      end

      it "publishes the updated package as a rc release" do
        prepare_nodejs_project do
          create_package_json :name => "my_package", :version => "1.0.0"
          add_changeset :patch
        end
        confirm_publish_package
        output = run_publish(["--rc"], :lang => :nodejs)

        project_dir = current_project_path
        next_version = "1.0.1-rc.1"
        tag = "v#{next_version}"

        expect(output).to has_publish_and_update_summary(
          :my_package => { :old => "v1.0.0", :new => "v1.0.1-rc.1", :bump => :patch }
        )

        in_project do
          expect(File.read("package.json")).to include(%("version": "#{next_version}"))
        end

        expect(performed_commands).to eql([
          [project_dir, "npm install"],
          [project_dir, "npm link"],
          [project_dir, "git tag --list #{tag}"],
          [project_dir, "npm run build"],
          [project_dir, "git add -A"],
          [
            project_dir,
            "git commit -m 'Publish package #{tag}' -m 'Update version number and CHANGELOG.md.'"
          ],
          [project_dir, "git tag #{tag}"],
          [project_dir, "npm publish --tag rc"],
          [project_dir, "git push origin main #{tag}"]
        ])
        expect(exit_status).to eql(0), output
      end
    end

    context "with mono Node.js project" do
      it "publishes the updated package" do
        prepare_nodejs_project "packages_dir" => "packages/" do
          create_package :package_one do
            create_package_json :version => "1.0.0"
            add_changeset :patch
          end
          create_package :package_two do
            create_package_json :version => "2.0.0"
          end
        end
        confirm_publish_package
        output = run_publish(:lang => :nodejs)

        project_dir = current_project_path
        package_one_dir = "#{project_dir}/packages/package_one"
        package_two_dir = "#{project_dir}/packages/package_two"
        next_version = "1.0.1"
        tag = "package_one@#{next_version}"

        expect(output).to has_publish_and_update_summary(
          :package_one => {
            :old => "package_one@1.0.0",
            :new => "package_one@1.0.1",
            :bump => :patch
          },
          :package_two => :no_publish
        )

        in_project do
          in_package "package_one" do
            expect(File.read("package.json")).to include(%("version": "#{next_version}"))

            changelog = read_changelog_file
            expect_changelog_to_include_version_header(changelog, next_version)
            expect_changelog_to_include_release_notes(changelog, :patch)
          end

          expect(local_changes?).to be_falsy, local_changes.inspect
          expect(commited_files).to eql([
            "packages/package_one/.changesets/1_patch.md",
            "packages/package_one/CHANGELOG.md",
            "packages/package_one/package.json"
          ])
        end

        expect(performed_commands).to eql([
          [project_dir, "npm install"],
          [package_one_dir, "npm link"],
          [package_two_dir, "npm link"],
          [project_dir, "git tag --list #{tag}"],
          [project_dir, "npm run build --workspace=package_one"],
          [project_dir, "git add -A"],
          [
            project_dir,
            "git commit -m 'Publish package #{tag}' -m 'Update version number and CHANGELOG.md.'"
          ],
          [project_dir, "git tag #{tag}"],
          [package_one_dir, "npm publish"],
          [project_dir, "git push origin main #{tag}"]
        ])
        expect(exit_status).to eql(0), output
      end

      it "publishes multiple packages" do
        prepare_nodejs_project "packages_dir" => "packages/" do
          create_package :package_one do
            create_package_json :version => "1.0.0"
            add_changeset :patch
          end
          create_package :package_two do
            create_package_json :version => "2.3.4"
            add_changeset :patch
          end
        end
        confirm_publish_package
        output = run_publish(:lang => :nodejs)

        project_dir = current_project_path
        package_one_dir = "#{project_dir}/packages/package_one"
        package_two_dir = "#{project_dir}/packages/package_two"
        next_version_one = "1.0.1"
        next_version_two = "2.3.5"
        package_one_tag = "package_one@#{next_version_one}"
        package_two_tag = "package_two@#{next_version_two}"

        expect(output).to has_publish_and_update_summary(
          :package_one => {
            :old => "package_one@1.0.0",
            :new => "package_one@1.0.1",
            :bump => :patch
          },
          :package_two => {
            :old => "package_two@2.3.4",
            :new => "package_two@2.3.5",
            :bump => :patch
          }
        )

        in_project do
          in_package "package_one" do
            package_json = JSON.parse(File.read("package.json"))
            expect(package_json["version"]).to eql(next_version_one)

            changelog = read_changelog_file
            expect_changelog_to_include_version_header(changelog, next_version_one)
            expect_changelog_to_include_release_notes(changelog, :patch)
          end

          in_package "package_two" do
            package_json = JSON.parse(File.read("package.json"))
            expect(package_json["version"]).to eql(next_version_two)

            changelog = read_changelog_file
            expect_changelog_to_include_version_header(changelog, next_version_two)
            expect_changelog_to_include_release_notes(changelog, :patch)
          end

          expect(local_changes?).to be_falsy, local_changes.inspect
          expect(commited_files).to eql([
            "packages/package_one/.changesets/1_patch.md",
            "packages/package_one/CHANGELOG.md",
            "packages/package_one/package.json",
            "packages/package_two/.changesets/2_patch.md",
            "packages/package_two/CHANGELOG.md",
            "packages/package_two/package.json"
          ])
        end

        expect(performed_commands).to eql([
          [project_dir, "npm install"],
          [package_one_dir, "npm link"],
          [package_two_dir, "npm link"],
          [project_dir, "git tag --list #{package_one_tag} #{package_two_tag}"],
          [project_dir, "npm run build --workspace=package_one"],
          [project_dir, "npm run build --workspace=package_two"],
          [project_dir, "git add -A"],
          [
            project_dir,
            "git commit -m 'Publish packages' -m 'Update version number and CHANGELOG.md.\n\n" \
              "- #{package_one_tag}\n- #{package_two_tag}'"
          ],
          [project_dir, "git tag #{package_one_tag}"],
          [project_dir, "git tag #{package_two_tag}"],
          [package_one_dir, "npm publish"],
          [package_two_dir, "npm publish"],
          [project_dir, "git push origin main #{package_one_tag} #{package_two_tag}"]
        ])
        expect(exit_status).to eql(0), output
      end

      it "publishes the updated package with build artifacts" do
        prepare_nodejs_project "packages_dir" => "packages/" do
          create_package :package_a do
            File.write("constants.js", "000")
            create_package_json :version => "1.0.0",
              :scripts => {
                :prebuild => "echo 123 > constants.js"
              }
            add_changeset :patch
          end
        end
        confirm_publish_package
        output = run_publish(:lang => :nodejs)

        next_version_a = "1.0.1"

        in_project do
          in_package :package_a do
            package_json = JSON.parse(File.read("package.json"))
            expect(package_json["version"]).to eql(next_version_a)

            changelog = read_changelog_file
            expect_changelog_to_include_version_header(changelog, next_version_a)
            expect_changelog_to_include_release_notes(changelog, :patch)

            expect(File.read("constants.js")).to eql("123\n")
          end

          expect(local_changes?).to be_falsy, local_changes.inspect
          expect(commited_files).to eql([
            "packages/package_a/.changesets/1_patch.md",
            "packages/package_a/CHANGELOG.md",
            "packages/package_a/constants.js",
            "packages/package_a/package.json"
          ])
        end

        expect(exit_status).to eql(0), output
      end

      it "publishes dependent packages" do
        prepare_nodejs_project "packages_dir" => "packages/" do
          create_package :package_a do
            create_package_json :version => "1.0.0"
            add_changeset :patch
          end
          create_package :package_b do
            create_package_json :version => "2.3.4",
              :dependencies => { :package_a => "=1.0.0" }
          end
          create_package :package_c do
            create_package_json :version => "3.0.9",
              :dependencies => { :package_b => "=2.3.4" }
          end
        end
        confirm_publish_package
        output = run_publish(:lang => :nodejs)

        project_dir = current_project_path
        package_dir_a = "#{project_dir}/packages/package_a"
        package_dir_b = "#{project_dir}/packages/package_b"
        package_dir_c = "#{project_dir}/packages/package_c"
        next_version_a = "1.0.1"
        next_version_b = "2.3.5"
        next_version_c = "3.0.10"
        package_tag_a = "package_a@#{next_version_a}"
        package_tag_b = "package_b@#{next_version_b}"
        package_tag_c = "package_c@#{next_version_c}"

        expect(output).to has_publish_and_update_summary(
          :package_a => { :old => "package_a@1.0.0", :new => "package_a@1.0.1", :bump => :patch },
          :package_b => { :old => "package_b@2.3.4", :new => "package_b@2.3.5", :bump => :patch },
          :package_c => { :old => "package_c@3.0.9", :new => "package_c@3.0.10", :bump => :patch }
        )

        in_project do
          in_package :package_a do
            package_json = JSON.parse(File.read("package.json"))
            expect(package_json["version"]).to eql(next_version_a)

            changelog = read_changelog_file
            expect_changelog_to_include_version_header(changelog, next_version_a)
            expect_changelog_to_include_release_notes(changelog, :patch)
          end

          in_package :package_b do
            package_json = JSON.parse(File.read("package.json"))
            expect(package_json["version"]).to eql(next_version_b)
            expect(package_json["dependencies"]["package_a"]).to eql("=#{next_version_a}")

            changelog = read_changelog_file
            expect_changelog_to_include_version_header(changelog, next_version_b)
            expect_changelog_to_include_package_bump(changelog, :package_a, next_version_a)
          end

          in_package :package_c do
            package_json = JSON.parse(File.read("package.json"))
            expect(package_json["version"]).to eql(next_version_c)
            expect(package_json["dependencies"]["package_b"]).to eql("=#{next_version_b}")

            changelog = read_changelog_file
            expect_changelog_to_include_version_header(changelog, next_version_c)
            expect_changelog_to_include_package_bump(changelog, :package_b, next_version_b)
          end

          expect(local_changes?).to be_falsy, local_changes.inspect
          expect(commited_files).to eql([
            "packages/package_a/.changesets/1_patch.md",
            "packages/package_a/CHANGELOG.md",
            "packages/package_a/package.json",
            "packages/package_b/CHANGELOG.md",
            "packages/package_b/package.json",
            "packages/package_c/CHANGELOG.md",
            "packages/package_c/package.json"
          ])
        end

        expect(performed_commands).to eql([
          [project_dir, "npm install"],
          [package_dir_a, "npm link"],
          [package_dir_b, "npm link"],
          [package_dir_c, "npm link"],
          [project_dir, "git tag --list #{package_tag_a} #{package_tag_b} #{package_tag_c}"],
          [project_dir, "npm run build --workspace=package_a"],
          [project_dir, "npm run build --workspace=package_b"],
          [project_dir, "npm run build --workspace=package_c"],
          [project_dir, "git add -A"],
          [
            project_dir,
            "git commit -m 'Publish packages' -m 'Update version number and CHANGELOG.md.\n\n" \
              "- #{package_tag_a}\n- #{package_tag_b}\n- #{package_tag_c}'"
          ],
          [project_dir, "git tag #{package_tag_a}"],
          [project_dir, "git tag #{package_tag_b}"],
          [project_dir, "git tag #{package_tag_c}"],
          [package_dir_a, "npm publish"],
          [package_dir_b, "npm publish"],
          [package_dir_c, "npm publish"],
          [project_dir, "git push origin main #{package_tag_a} #{package_tag_b} #{package_tag_c}"]
        ])
        expect(exit_status).to eql(0), output
      end

      it "publishes dependent packages with prerelease" do
        prepare_nodejs_project "packages_dir" => "packages/" do
          create_package :package_a do
            create_package_json :version => "1.0.0"
            add_changeset :patch
          end
          create_package :package_b do
            create_package_json :version => "2.3.4",
              :dependencies => { :package_a => "=1.0.0" }
          end
        end
        confirm_publish_package
        output = run_publish(["--alpha"], :lang => :nodejs)

        project_dir = current_project_path
        package_dir_a = "#{project_dir}/packages/package_a"
        package_dir_b = "#{project_dir}/packages/package_b"
        next_version_a = "1.0.1-alpha.1"
        next_version_b = "2.3.5-alpha.1"
        package_tag_a = "package_a@#{next_version_a}"
        package_tag_b = "package_b@#{next_version_b}"

        expect(output).to has_publish_and_update_summary(
          :package_a => {
            :old => "package_a@1.0.0",
            :new => "package_a@1.0.1-alpha.1",
            :bump => :patch
          },
          :package_b => {
            :old => "package_b@2.3.4",
            :new => "package_b@2.3.5-alpha.1",
            :bump => :patch
          }
        )

        in_project do
          in_package :package_a do
            package_json = JSON.parse(File.read("package.json"))
            expect(package_json["version"]).to eql(next_version_a)

            changelog = read_changelog_file
            expect_changelog_to_include_version_header(changelog, next_version_a)
            expect_changelog_to_include_release_notes(changelog, :patch)
          end

          in_package :package_b do
            package_json = JSON.parse(File.read("package.json"))
            expect(package_json["version"]).to eql(next_version_b)
            expect(package_json["dependencies"]["package_a"]).to eql("=#{next_version_a}")

            changelog = read_changelog_file
            expect_changelog_to_include_version_header(changelog, next_version_b)
            expect_changelog_to_include_package_bump(changelog, :package_a, next_version_a)
          end

          expect(local_changes?).to be_falsy, local_changes.inspect
          expect(commited_files).to eql([
            "packages/package_a/.changesets/1_patch.md",
            "packages/package_a/CHANGELOG.md",
            "packages/package_a/package.json",
            "packages/package_b/CHANGELOG.md",
            "packages/package_b/package.json"
          ])
        end

        expect(performed_commands).to eql([
          [project_dir, "npm install"],
          [package_dir_a, "npm link"],
          [package_dir_b, "npm link"],
          [project_dir, "git tag --list #{package_tag_a} #{package_tag_b}"],
          [project_dir, "npm run build --workspace=package_a"],
          [project_dir, "npm run build --workspace=package_b"],
          [project_dir, "git add -A"],
          [
            project_dir,
            "git commit -m 'Publish packages' -m 'Update version number and CHANGELOG.md.\n\n" \
              "- #{package_tag_a}\n- #{package_tag_b}'"
          ],
          [project_dir, "git tag #{package_tag_a}"],
          [project_dir, "git tag #{package_tag_b}"],
          [package_dir_a, "npm publish --tag alpha"],
          [package_dir_b, "npm publish --tag alpha"],
          [project_dir, "git push origin main #{package_tag_a} #{package_tag_b}"]
        ])
        expect(exit_status).to eql(0), output
      end

      it "updates dependencies between packages and publishes packages" do
        prepare_nodejs_project "packages_dir" => "packages/" do
          create_package :package_a do
            create_package_json :version => "1.0.0"
            add_changeset :patch
          end
          create_package :package_b do
            create_package_json :version => "2.3.4",
              :dependencies => { :package_a => "=1.0.0" }
            add_changeset :patch
          end
        end
        confirm_publish_package
        output = run_publish(:lang => :nodejs)

        project_dir = current_project_path
        package_dir_a = "#{project_dir}/packages/package_a"
        package_dir_b = "#{project_dir}/packages/package_b"
        next_version_a = "1.0.1"
        next_version_b = "2.3.5"
        package_tag_a = "package_a@#{next_version_a}"
        package_tag_b = "package_b@#{next_version_b}"

        expect(output).to has_publish_and_update_summary(
          :package_a => {
            :old => "package_a@1.0.0",
            :new => "package_a@1.0.1",
            :bump => :patch
          },
          :package_b => {
            :old => "package_b@2.3.4",
            :new => "package_b@2.3.5",
            :bump => :patch
          }
        )

        in_project do
          in_package :package_a do
            package_json = JSON.parse(File.read("package.json"))
            expect(package_json["version"]).to eql(next_version_a)

            changelog = read_changelog_file
            expect_changelog_to_include_version_header(changelog, next_version_a)
            expect_changelog_to_include_release_notes(changelog, :patch)
          end

          in_package :package_b do
            package_json = JSON.parse(File.read("package.json"))
            expect(package_json["version"]).to eql(next_version_b)
            expect(package_json["dependencies"]["package_a"]).to eql("=#{next_version_a}")

            changelog = read_changelog_file
            expect_changelog_to_include_version_header(changelog, next_version_b)
            expect_changelog_to_include_package_bump(changelog, :package_a, next_version_a)
          end

          expect(local_changes?).to be_falsy, local_changes.inspect
          expect(commited_files).to eql([
            "packages/package_a/.changesets/1_patch.md",
            "packages/package_a/CHANGELOG.md",
            "packages/package_a/package.json",
            "packages/package_b/.changesets/2_patch.md",
            "packages/package_b/CHANGELOG.md",
            "packages/package_b/package.json"
          ])
        end

        expect(performed_commands).to eql([
          [project_dir, "npm install"],
          [package_dir_a, "npm link"],
          [package_dir_b, "npm link"],
          [project_dir, "git tag --list #{package_tag_a} #{package_tag_b}"],
          [project_dir, "npm run build --workspace=package_a"],
          [project_dir, "npm run build --workspace=package_b"],
          [project_dir, "git add -A"],
          [
            project_dir,
            "git commit -m 'Publish packages' -m 'Update version number and CHANGELOG.md.\n\n" \
              "- #{package_tag_a}\n- #{package_tag_b}'"
          ],
          [project_dir, "git tag #{package_tag_a}"],
          [project_dir, "git tag #{package_tag_b}"],
          [package_dir_a, "npm publish"],
          [package_dir_b, "npm publish"],
          [project_dir, "git push origin main #{package_tag_a} #{package_tag_b}"]
        ])
        expect(exit_status).to eql(0), output
      end
    end
  end

  context "with yarn" do
    context "with single Node.js package" do
      it "publishes the updated package" do
        prepare_nodejs_project "npm_client" => "yarn" do
          create_package_json :name => "my_package", :version => "1.0.0"
          add_changeset :patch
        end
        confirm_publish_package
        output = run_publish(:lang => :nodejs)

        project_dir = current_project_path
        next_version = "1.0.1"
        tag = "v#{next_version}"

        expect(output).to has_publish_and_update_summary(
          :my_package => { :old => "v1.0.0", :new => "v1.0.1", :bump => :patch }
        )

        in_project do
          expect(File.read("package.json")).to include(%("version": "#{next_version}"))

          changelog = read_changelog_file
          expect_changelog_to_include_version_header(changelog, next_version)
          expect_changelog_to_include_release_notes(changelog, :patch)

          expect(local_changes?).to be_falsy, local_changes.inspect
          expect(commited_files).to eql([
            ".changesets/1_patch.md",
            "CHANGELOG.md",
            "package.json"
          ])
        end

        expect(performed_commands).to eql([
          [project_dir, "yarn install"],
          [project_dir, "yarn link"],
          [project_dir, "git tag --list #{tag}"],
          [project_dir, "yarn run build"],
          [project_dir, "git add -A"],
          [
            project_dir,
            "git commit -m 'Publish package #{tag}' -m 'Update version number and CHANGELOG.md.'"
          ],
          [project_dir, "git tag #{tag}"],
          [project_dir, "yarn publish --new-version #{next_version}"],
          [project_dir, "git push origin main #{tag}"]
        ])
        expect(exit_status).to eql(0), output
      end
    end
  end
end
