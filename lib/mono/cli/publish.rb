# frozen_string_literal: true

module Mono
  module Cli
    class Publish < Base
      attr_reader :prerelease
      alias prerelease? prerelease

      def initialize(options = {})
        @prerelease = options[:prerelease]
        super(options)
      end

      def execute
        exit_cli "No packages found in this directory!" unless packages.any?

        if prerelease?
          # Tell to-be-published packages that they should update to a
          # prerelease
          packages.each do |package|
            package.prerelease = prerelease
          end
        end

        changed_packages = package_promoter.changed_packages
        unless changed_packages.any?
          exit_cli "No packages found to publish! No changes detected."
        end

        if local_changes?
          exit_cli "Error: There are local changes before building. " \
            "Commit or discard them and try again. Exiting."
        end

        print_summary(packages)
        puts
        ask_for_confirmation
        puts
        update_packages(changed_packages)
        puts
        update_changelog(changed_packages)
        puts
        build(changed_packages)
        puts
        commit_changes(changed_packages)
        puts
        publish_package_manager(changed_packages)
        puts
        publish_git(changed_packages)
      end

      private

      def ask_for_confirmation
        publish = yes_or_no "Do you want to publish the above changes? (Y/n) ",
          :default => "y"
        return if publish

        exit_with_status 1
      end

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
            print_package_summary(package)
          else
            puts "- #{package.name}: (Will not publish)"
          end
        end
      end

      def update_packages(packages)
        puts "# Updating package versions"
        packages.each do |package|
          print_package_summary(package)
          package.update_spec
        end
      end

      def print_package_summary(package)
        puts "- #{package.name}:"
        puts "  Current version: #{package.current_tag}"
        puts "  Next version:    #{package.next_tag} (#{package.next_bump})"
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
        run_command "git add -A"
        run_command \
          "git commit -m 'Publish packages [ci skip]' -m '#{packages_list}'"

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
