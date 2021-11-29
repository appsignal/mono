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
      new_messages = Hash.new { |hash, key| hash[key] = [] }
      sets = changesets.sort_by { |set| [set.bump_index, set.date] }
      sets.each do |changeset|
        new_messages[changeset.type] << build_changelog_entry(changeset)
      end
      content = []
      Changeset::SUPPORTED_TYPES.each do |label, value|
        messages_for_type = new_messages[value]
        next if messages_for_type.empty?

        content << "\n### #{label}\n\n"
        messages_for_type.each do |message|
          content << message
        end
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

          #{content.join.strip}

          #{lines.join.strip}
        CHANGELOG
      end
      changesets.each(&:remove)
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

    private

    def build_changelog_entry(changeset)
      message = ["- "]
      commit = changeset.commit
      if commit
        url = "#{config.repo}/commit/#{commit[:long]}"
        message << "[#{commit[:short]}](#{url}) "
      end
      message << changeset.bump
      message << " - #{changeset.message.lines.join("  ")}\n"
      message.join
    end
  end
end
