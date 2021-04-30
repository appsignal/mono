# frozen_string_literal: true

module Mono
  module Cli
    class Publish < Base
      def execute
        exit_cli "No packages found!" unless packages.any?

        selected_packages = packages_to_publish
        unless selected_packages.any?
          exit_cli "No packages found to publish! No changes detected."
        end

        if local_changes?
          exit_cli "Error: There are local changes before building. " \
            "Commit or discard them and try again. Exiting."
        end

        print_summary(packages)
        puts
        update_package_versions(selected_packages)
        puts
        update_changelog(selected_packages)
        puts
        build(selected_packages)
        puts
        commit_changes(selected_packages)
        puts
        publish_package_manager(selected_packages)
        puts
        publish_git(selected_packages)
      end

      private

      def build(packages)
        puts "# Building packages"
        run_hooks("build", "pre")
        packages.each do |package|
          puts "# Building package: #{package.name} (#{package.path})"
          package.build
        end
        run_hooks("build", "post")
      end

      def print_summary(packages)
        puts "The following packages will be published (or not):"
        packages.each do |package|
          if package.will_update?
            puts "- #{package.name}:"
            puts "  Current version: #{package.current_tag}"
            puts "  Next version:    #{package.next_tag} (#{package.next_bump})"
          else
            puts "- #{package.name}: (Will not publish)"
          end
        end
      end

      def update_package_versions(packages)
        puts "# Updating package versions"
        packages.each do |package|
          puts "# Updating package version: #{package.name}"
          puts "Current version: #{package.current_tag}"
          puts "Next version:    #{package.next_tag} (#{package.next_bump})"
          package.write_new_version
        end
      end

      def update_changelog(packages)
        puts "# Updating changelogs"
        packages.each do |package|
          puts "# Updating changelog: #{package.name} (#{package.path})"
          package.changesets.write_changesets_to_changelog
        end
      end

      def publish_package_manager(packages)
        puts "# Publishing to package manager"
        run_hooks("publish", "pre")
        packages.each do |package|
          puts "# Publish package #{package.next_tag}"
          package.publish_next_version
        end
        run_hooks("publish", "post")
      end

      def commit_changes(packages)
        run_hooks("git-commit", "pre")
        puts "# Publishing to git"
        puts "## Creating release commit"
        packages_list =
          packages.map do |package|
            "- #{package.next_tag}"
          end.join("\n")
        run_command \
          "git commit -am 'Publish packages [ci skip]' -m '#{packages_list}'"

        packages.each do |package|
          puts "## Tag package #{package.next_tag}"
          run_command "git tag #{package.next_tag}"
        end
        run_hooks("git-commit", "post")
      end

      def publish_git(packages)
        run_hooks("git-publish", "pre")
        puts "# Publishing to git"
        puts "## Pushing to git remote origin"
        package_versions = packages.map(&:next_tag).join(" ")
        run_command "git push origin #{current_branch} #{package_versions}"
        run_hooks("git-publish", "post")
      end
    end
  end
end
