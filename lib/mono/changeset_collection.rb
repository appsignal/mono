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

    def changesets_by_types_sorted_by_bump
      collection = Hash.new { |hash, key| hash[key] = [] }
      changesets
        .sort_by { |set| [set.type_index, set.bump_index, set.date] }
        .each { |changeset| collection[changeset.type] << changeset }
      collection
    end

    def formatted_changesets(format: :changelog)
      changesets_by_type = changesets_by_types_sorted_by_bump
      content = []
      Changeset::SUPPORTED_TYPES.each do |key, label|
        messages_for_type = changesets_by_type[key]
        next if messages_for_type.empty?

        heading_level = format == :changelog ? 3 : 2
        heading = "#" * heading_level
        content << "\n#{heading} #{label}\n\n"
        messages_for_type.each do |changeset|
          content << build_changelog_entry(changeset, :format => format)
        end
      end
      content
    end

    def write_changesets_to_changelog
      content = formatted_changesets(:format => :changelog)

      changelog_path = File.join(package.path, "CHANGELOG.md")
      FileUtils.touch(changelog_path)
      contents = File.read(changelog_path)
      lines = contents.lines # Keep original contents to add to the bottom
      heading = lines.shift # Keep original heading
      date = Time.now.utc.strftime("%Y-%m-%d")
      File.write(changelog_path, <<~CHANGELOG)
        #{heading}
        ## #{package.next_version}

        _Published on #{date}._

        #{content.join.strip}

        #{lines.join.strip}
      CHANGELOG
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

    CHANGELOG_INDENT = " " * 2

    def build_changelog_entry(changeset, format: :changelog)
      changeset_message = indent_message(changeset.message)
      message = ["- #{changeset_message.strip}"]
      if format == :changelog
        message <<
          if changeset_message.lines.count > 1
            "\n\n#{CHANGELOG_INDENT}"
          else
            " "
          end
        commits = []
        changeset.commits.reverse_each do |commit|
          url = "#{config.repo}/commit/#{commit[:long]}"
          commits << "[#{commit[:short]}](#{url})"
        end
        formatted_commits = " #{commits.join(", ")}" if commits.any?
        message << "(#{changeset.bump}#{formatted_commits})"
      end
      message << "\n"
      message.join
    end

    def indent_message(message)
      message
        .lines
        .map { |line| "#{CHANGELOG_INDENT}#{line}".rstrip }
        .join("\n")
    end
  end
end
