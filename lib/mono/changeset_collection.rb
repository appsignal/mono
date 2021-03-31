# frozen_string_literal: true

require "fileutils"

module Mono
  class ChangesetCollection
    attr_reader :config, :package

    def initialize(config, package)
      @config = config
      @package = package
    end

    def any?
      changesets.any?
    end

    def changesets
      @changesets ||=
        Dir.glob(File.join(package.path, ".changesets/*")).map do |file|
          Changeset.parse(file)
        end
    end

    def write_changesets_to_changelog
      new_messages = []
      sets = changesets.sort_by { |set| [set.bump, set.commit[:date]] }
      sets.each do |changeset|
        commit = changeset.commit
        url = "#{config.repo}/commit/#{commit[:long]}"
        new_messages << "- [#{commit[:short]}](#{url}) #{changeset.bump} - " \
          "#{changeset.message.lines.join("  ")}\n"
      end
      changelog_path = File.join(package.path, "CHANGELOG.md")
      FileUtils.touch(changelog_path)
      contents = File.read(changelog_path)
      lines = contents.lines # Keep original contents to add to the bottom
      heading = lines.shift # Keep original heading
      File.open(changelog_path, "w+") do |file|
        file.write(<<~CHANGELOG)
          #{heading}
          ## #{package.next_version}

          #{new_messages.join("").chomp}

          #{lines.join("").strip}
        CHANGELOG
      end
      changesets.each do |changeset|
        FileUtils.rm changeset.path
      end
    end

    def next_bump
      bumps = changesets.map(&:bump).uniq
      if bumps.include?("major")
        "major"
      elsif bumps.include?("minor")
        "minor"
      elsif bumps.include?("patch")
        "patch"
      end
    end
  end
end
