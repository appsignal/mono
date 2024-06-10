# frozen_string_literal: true

module Mono
  module Cli
    # rubocop:disable Metrics/ClassLength
    class Publish < Base
      TMP_DIR = "tmp"

      attr_reader :prerelease, :tag
      alias prerelease? prerelease
      alias tag? tag

      def initialize(options = {})
        @prerelease = options[:prerelease]
        @tag = options[:tag]
        super(options)
      end

      def execute # rubocop:disable Metrics/MethodLength
        if prerelease? && tag?
          exit_cli "Error: Both a prerelease flag (--alpha, --beta, --rc) " \
            "and --tag options are set. Only one can be used at a time to " \
            "tag a release. Exiting."
        end

        exit_cli "No packages found in this directory!" unless packages.any?

        packages.each do |package|
          # Tell to-be-published packages that they should update to a
          # prerelease
          package.prerelease = prerelease if prerelease?
          package.tag = tag if tag?
        end

        changed_packages = package_promoter.changed_packages
        unless changed_packages.any?
          exit_cli "No packages found to publish! No changes detected."
        end

        if local_changes?
          exit_cli "Error: There are local changes before building. " \
            "Commit or discard them and try again. Exiting."
        end

        if git?
          existing_tags = existing_tags(changed_packages)
          unless existing_tags.empty?
            message = "Error: The Git tags for packages to be published " \
              "already exist: "
            message += existing_tags.map(&:inspect).join(",")
            message += ". Delete them and try again. Exiting."
            exit_cli message
          end
        end

        print_summary(packages)
        puts
        ask_for_publish_confirmation if ask_for_confirmation?
        puts

        rollback = []

        begin
          changesets =
            packages.to_h do |package|
              [
                package.name,
                package.changesets.formatted_changesets(:format => :short)
              ]
            end

          update_packages(changed_packages, rollback)
          puts
          update_changelog(changed_packages, rollback)
          puts
          build(changed_packages)
          puts
          commit_changes(changed_packages, changesets, rollback) if git?
          puts
          publish_package_manager(changed_packages) if package_push?
        rescue => error
          puts
          ask_for_rollback_confirmation(error)
          puts
          rollback_changes(rollback)
          exit_with_status 1
        end

        puts
        publish_git(changed_packages) if git?
      end

      private

      def ask_for_confirmation?
        options.fetch(:ask_for_confirmation, true)
      end

      def git?
        options.fetch(:git, true)
      end

      def package_push?
        options.fetch(:package_push, true)
      end

      def ask_for_publish_confirmation
        publish = yes_or_no "Do you want to publish the above changes? (Y/n) ",
          :default => "y"
        return if publish

        exit_with_status 1
      end

      def ask_for_rollback_confirmation(error)
        puts(
          "A Mono error was encountered during the `mono publish` command. " \
            "Stopping operation."
        )
        puts
        puts "#{error.class}: #{error.message}"
        puts

        rollback = yes_or_no(
          "Do you want to rollback the above changes? " \
            "(Y/n) ",
          :default => "y"
        )
        return if rollback

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
            print_package_changesets(package)
          else
            puts "- #{package.name}: (Will not publish)"
          end
        end
      end

      def update_packages(packages, rollback)
        puts "# Updating package versions"
        packages.each do |package|
          print_package_summary(package)
          package.update_spec
        end
        rollback << [
          "## Restoring package versions",
          "git restore :/"
        ]
      end

      def print_package_summary(package)
        puts "- #{package.name}:"
        puts "  Current version: #{package.current_tag}"
        puts "  Next version:    #{package.next_tag} (#{package.next_bump})"
      end

      def print_package_changesets(package)
        puts "  Changesets:"
        # Sort by output the same way as the changelog result
        changesets_by_type =
          package.changesets.changesets_by_types_sorted_by_bump
        changesets_by_type.each do |_, changesets|
          changesets.each do |changeset|
            # Clean up the description from indenting and new lines so the
            # formatting doesn't break
            description = changeset.message
              .gsub(/\n\s+/, " ") # Strip out any indenting in new lines
              .tr("\n", " ") # Strip out any remaining new lines
            # Trim long changeset messages
            if description.length > 100
              description = "#{description[0...100]}..."
            end
            puts "  - #{changeset.type_label} - " \
              "#{changeset.bump}: #{changeset.path}"
            puts "      #{description}"
          end
        end
      end

      def update_changelog(packages, rollback)
        puts "# Updating changelogs"
        packages.each do |package|
          puts "# Updating changelog: #{package.name} (#{package.path})"
          package.changesets.write_changesets_to_changelog
        end
        rollback << [
          "## Restoring changelogs",
          "git restore :/"
        ]
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

      def commit_changes(packages, changesets, rollback)
        run_hooks("git-commit", "pre")
        puts "# Committing changes to Git"
        puts "## Creating release commit"
        standard_message =
          "Update version number and CHANGELOG.md."
        commit_subject, commit_message =
          if packages.length > 1
            message =
              packages.map do |package|
                "- #{package.next_tag}"
              end.join("\n")
            ["Publish packages", "#{standard_message}\n\n#{message}"]
          else
            only_package = packages.first
            ["Publish package #{only_package.next_tag}", standard_message]
          end
        run_command "git add -A"
        rollback << [
          "## Removing release commit",
          "git restore --staged :/"
        ]
        run_command "git commit -m '#{commit_subject}' -m '#{commit_message}'"
        rollback << [
          "## Removing release commit",
          "git reset --soft HEAD^"
        ]

        packages.each do |package|
          puts "## Tag package #{package.next_tag}"

          prepare_tmp_dir
          tmp_file = File.join(TMP_DIR, "#{package.name}_changesets.txt")
          File.write(tmp_file, changesets[package.name].join)

          run_command "git tag #{package.next_tag} " \
            "--annotate --cleanup=verbatim --file #{tmp_file}"
          FileUtils.rm(tmp_file)
          rollback << [
            "## Untag package #{package.next_tag}",
            "git tag -d #{package.next_tag}"
          ]
        end
        run_hooks("git-commit", "post")
      end

      def prepare_tmp_dir
        FileUtils.mkdir_p(TMP_DIR)
      end

      def publish_git(packages)
        run_hooks("git-publish", "pre")
        puts "# Publishing to Git"
        puts "## Pushing to Git remote origin"
        package_versions = packages.map(&:next_tag).join(" ")
        run_command "git push origin #{current_branch} #{package_versions}"
        run_hooks("git-publish", "post")
      end

      # Helper class to update dependencies between packages in a mono project
      def package_promoter
        @package_promoter ||=
          PackagePromoter.new(dependency_tree, :prerelease => prerelease)
      end

      def existing_tags(changed_packages)
        next_tags = changed_packages.map(&:next_tag).join(" ")
        run_command(
          "git tag --list #{next_tags}",
          :capture => true,
          :print_command => false
        ).strip.split("\n")
      end

      def rollback_changes(rollback)
        puts "# Rolling back changes"
        last_message = nil
        last_command = nil
        rollback.reverse.each do |rollback_entry|
          message = rollback_entry.first
          command = rollback_entry.last

          puts message unless message == last_message
          run_command(command) unless command == last_command

          last_message = message
          last_command = command
        end
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
