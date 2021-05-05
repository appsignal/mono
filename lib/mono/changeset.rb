# frozen_string_literal: true

require "time"

module Mono
  class Changeset
    attr_reader :path, :message

    SUPPORTED_BUMPS = %w[major minor patch].freeze
    YAML_FRONT_MATTER_REGEXP =
      /\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m.freeze

    class MetadataError < Mono::Error; end

    class EmptyMessageError < Mono::Error; end

    class UnknownBumpTypeError < Mono::Error; end

    def self.supported_bump?(bump)
      SUPPORTED_BUMPS.include?(bump)
    end

    def self.parse(file)
      contents = File.read(file)
      frontmatter_matches = YAML_FRONT_MATTER_REGEXP.match(contents)
      metadata =
        if frontmatter_matches
          YAML.safe_load(frontmatter_matches[1])
        else
          raise MetadataError, "No metadata found for changeset: `#{file}`. " \
            "Please specify either a major, minor or patch version bump."
        end
      message = contents.sub(frontmatter_matches[0], "").strip
      if message.strip.empty?
        raise EmptyMessageError,
          "No changeset message found for changeset: `#{file}`. " \
          "Please add a description of the change."
      end
      new(file, metadata, message)
    end

    def initialize(path, metadata, message)
      @path = path
      @metadata = metadata
      @message = message
      validate
    end

    def validate
      unless SUPPORTED_BUMPS.include?(@metadata["bump"])
        raise UnknownBumpTypeError,
          "Unknown bump type specified for changeset: `#{path}`. " \
          "Please specify either major, minor or patch."
      end
    end

    def bump
      @metadata["bump"]
    end

    def commit
      @commit ||=
        begin
          git_log = `git log -n 1 --pretty="format:%h %H %cI" -- #{path}`
          short, long, date = git_log.split(" ")
          {
            :short => short,
            :long => long,
            :date => Time.parse(date)
          }
        end
    end
  end
end
