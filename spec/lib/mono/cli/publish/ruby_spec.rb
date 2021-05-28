# frozen_string_literal: true

RSpec.describe Mono::Cli::Publish do
  include PublishHelper

  around { |example| with_mock_stdin { example.run } }

  context "with single Ruby package" do
    it "publishes the package" do
      prepare_ruby_project do
        create_package_gemspec :name => "mygem", :version => "1.2.3"
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
        [project_dir, "gem push mygem-#{next_version}.gem"],
        [project_dir, "git push origin main v#{next_version}"]
      ])
      expect(exit_status).to eql(0), output
    end

    context "with multiple .gem files" do
      it "only publishes this version's gemfiles" do
        prepare_ruby_project do
          create_package_gemspec :name => "mygem", :version => "1.2.3"
          add_changeset :patch
          FileUtils.touch("mygem-1.2.3.gem")
          FileUtils.touch("mygem-1.2.4-java.gem")
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
          [project_dir, "gem push mygem-#{next_version}.gem"],
          [project_dir, "gem push mygem-#{next_version}-java.gem"],
          [project_dir, "git push origin main v#{next_version}"]
        ])
        expect(exit_status).to eql(0), output
      end
    end
  end

  context "with mono Ruby package" do
    it "publishes the updated package" do
      prepare_ruby_project "packages_dir" => "packages/" do
        create_package :package_a do
          create_package_gemspec :name => "package_a", :version => "1.2.3"
          add_changeset :patch
        end
        create_package :package_b do
          create_package_gemspec :name => "package_b", :version => "2.0.0"
        end
      end
      confirm_publish_package
      output = run_publish_process

      project_dir = "/#{current_project}"
      package_dir_a = "#{project_dir}/packages/package_a"
      next_version_a = "1.2.4"
      tag_a = "package_a@#{next_version_a}"

      expect(output).to include(<<~OUTPUT), output
        The following packages will be published (or not):
        - package_a:
          Current version: package_a@1.2.3
          Next version:    package_a@1.2.4 (patch)
        - package_b: (Will not publish)
      OUTPUT
      expect(output).to include(<<~OUTPUT), output
        # Updating package versions
        - package_a:
          Current version: package_a@1.2.3
          Next version:    package_a@1.2.4 (patch)
      OUTPUT

      in_project do
        in_package :package_a do
          expect(File.read("lib/example/version.rb")).to include(%(VERSION = "#{next_version_a}"))
          expect(current_package_changeset_files.length).to eql(0)

          changelog = File.read("CHANGELOG.md")
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
        [package_dir_a, "gem build"],
        [project_dir, "git add -A"],
        [project_dir, "git commit -m 'Publish packages [ci skip]' -m '- #{tag_a}'"],
        [project_dir, "git tag #{tag_a}"],
        [project_dir, "gem push packages/package_a/package_a-#{next_version_a}.gem"],
        [project_dir, "git push origin main #{tag_a}"]
      ])
      expect(exit_status).to eql(0), output
    end

    it "publishes multiple updated packages" do
      prepare_ruby_project "packages_dir" => "packages/" do
        create_package :package_a do
          create_package_gemspec :name => "package_a", :version => "1.2.3"
          add_changeset :patch
        end
        create_package :package_b do
          create_package_gemspec :name => "package_b", :version => "2.0.0"
          add_changeset :patch
        end
      end
      confirm_publish_package
      output = run_publish_process

      project_dir = "/#{current_project}"
      package_dir_a = "#{project_dir}/packages/package_a"
      package_dir_b = "#{project_dir}/packages/package_b"
      next_version_a = "1.2.4"
      next_version_b = "2.0.1"
      tag_a = "package_a@#{next_version_a}"
      tag_b = "package_b@#{next_version_b}"

      expect(output).to include(<<~OUTPUT), output
        The following packages will be published (or not):
        - package_a:
          Current version: package_a@1.2.3
          Next version:    package_a@1.2.4 (patch)
        - package_b:
          Current version: package_b@2.0.0
          Next version:    package_b@2.0.1 (patch)
      OUTPUT
      expect(output).to include(<<~OUTPUT), output
        # Updating package versions
        - package_a:
          Current version: package_a@1.2.3
          Next version:    package_a@1.2.4 (patch)
        - package_b:
          Current version: package_b@2.0.0
          Next version:    package_b@2.0.1 (patch)
      OUTPUT

      in_project do
        in_package :package_a do
          expect(File.read("lib/example/version.rb")).to include(%(VERSION = "#{next_version_a}"))
          expect(current_package_changeset_files.length).to eql(0)

          changelog = File.read("CHANGELOG.md")
          expect_changelog_to_include_version_header(changelog, next_version_a)
          expect_changelog_to_include_release_notes(changelog, :patch)
        end

        in_package :package_b do
          expect(File.read("lib/example/version.rb")).to include(%(VERSION = "#{next_version_b}"))
          expect(current_package_changeset_files.length).to eql(0)

          changelog = File.read("CHANGELOG.md")
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
        [package_dir_a, "gem build"],
        [package_dir_b, "gem build"],
        [project_dir, "git add -A"],
        [project_dir, "git commit -m 'Publish packages [ci skip]' -m '- #{tag_a}\n- #{tag_b}'"],
        [project_dir, "git tag #{tag_a}"],
        [project_dir, "git tag #{tag_b}"],
        [project_dir, "gem push packages/package_a/package_a-#{next_version_a}.gem"],
        [project_dir, "gem push packages/package_b/package_b-#{next_version_b}.gem"],
        [project_dir, "git push origin main #{tag_a} #{tag_b}"]
      ])
      expect(exit_status).to eql(0), output
    end

    it "publishes depenent packages" do
      prepare_ruby_project "packages_dir" => "packages/" do
        create_package :package_a do
          create_package_gemspec :name => "package_a", :version => "1.2.3"
          add_changeset :patch
        end
        create_package :package_b do
          create_package_gemspec :name => "package_b",
            :version => "2.0.0",
            :dependencies => { "package_a" => "1.2.3" }
        end
        create_package :package_c do
          create_package_gemspec :name => "package_c",
            :version => "3.3.0",
            :dependencies => { "package_b" => "2.0.0" }
        end
      end
      confirm_publish_package
      output = run_publish_process

      project_dir = "/#{current_project}"
      package_dir_a = "#{project_dir}/packages/package_a"
      package_dir_b = "#{project_dir}/packages/package_b"
      package_dir_c = "#{project_dir}/packages/package_c"
      next_version_a = "1.2.4"
      next_version_b = "2.0.1"
      next_version_c = "3.3.1"
      tag_a = "package_a@#{next_version_a}"
      tag_b = "package_b@#{next_version_b}"
      tag_c = "package_c@#{next_version_c}"

      expect(output).to include(<<~OUTPUT), output
        The following packages will be published (or not):
        - package_a:
          Current version: package_a@1.2.3
          Next version:    package_a@1.2.4 (patch)
        - package_b:
          Current version: package_b@2.0.0
          Next version:    package_b@2.0.1 (patch)
        - package_c:
          Current version: package_c@3.3.0
          Next version:    package_c@3.3.1 (patch)
      OUTPUT
      expect(output).to include(<<~OUTPUT), output
        # Updating package versions
        - package_a:
          Current version: package_a@1.2.3
          Next version:    package_a@1.2.4 (patch)
        - package_b:
          Current version: package_b@2.0.0
          Next version:    package_b@2.0.1 (patch)
        - package_c:
          Current version: package_c@3.3.0
          Next version:    package_c@3.3.1 (patch)
      OUTPUT

      in_project do
        in_package :package_a do
          expect(File.read("lib/example/version.rb")).to include(%(VERSION = "#{next_version_a}"))
          expect(current_package_changeset_files.length).to eql(0)

          changelog = File.read("CHANGELOG.md")
          expect_changelog_to_include_version_header(changelog, next_version_a)
          expect_changelog_to_include_release_notes(changelog, :patch)
        end

        in_package :package_b do
          expect(File.read("lib/example/version.rb")).to include(%(VERSION = "#{next_version_b}"))
          expect(current_package_changeset_files.length).to eql(0)

          changelog = File.read("CHANGELOG.md")
          expect_changelog_to_include_version_header(changelog, next_version_b)
          expect_changelog_to_include_package_bump(changelog, "package_a", next_version_a)
        end

        in_package :package_c do
          expect(File.read("lib/example/version.rb")).to include(%(VERSION = "#{next_version_c}"))
          expect(current_package_changeset_files.length).to eql(0)

          changelog = File.read("CHANGELOG.md")
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

      message = "- #{tag_a}\n- #{tag_b}\n- #{tag_c}"
      expect(performed_commands).to eql([
        [package_dir_a, "gem build"],
        [package_dir_b, "gem build"],
        [package_dir_c, "gem build"],
        [project_dir, "git add -A"],
        [project_dir, "git commit -m 'Publish packages [ci skip]' -m '#{message}'"],
        [project_dir, "git tag #{tag_a}"],
        [project_dir, "git tag #{tag_b}"],
        [project_dir, "git tag #{tag_c}"],
        [project_dir, "gem push packages/package_a/package_a-#{next_version_a}.gem"],
        [project_dir, "gem push packages/package_b/package_b-#{next_version_b}.gem"],
        [project_dir, "gem push packages/package_c/package_c-#{next_version_c}.gem"],
        [project_dir, "git push origin main #{tag_a} #{tag_b} #{tag_c}"]
      ])
      expect(exit_status).to eql(0), output
    end
  end

  def prepare_ruby_project(config = {})
    prepare_new_project do
      create_mono_config({ "language" => "ruby" }.merge(config))
      yield
    end
  end

  def run_publish_process
    capture_stdout do
      in_project do
        perform_commands do
          stub_commands [/^gem push/, /^git push/] do
            run_publish
          end
        end
      end
    end
  end
end
