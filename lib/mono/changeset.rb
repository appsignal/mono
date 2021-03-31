# frozen_string_literal: true

require "time"

module Mono
  class Changeset
    attr_reader :path, :message

    YAML_FRONT_MATTER_REGEXP =
      /\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m.freeze

    def self.parse(file)
      contents = File.read(file)
      frontmatter_matches = YAML_FRONT_MATTER_REGEXP.match(contents)
      metadata = YAML.safe_load(frontmatter_matches[1])
      message = contents.sub(frontmatter_matches[0], "").strip
      new(file, metadata, message)
    end

    def initialize(path, metadata, message)
      @path = path
      @metadata = metadata
      @message = message
      validate
    end

    def validate
      unless @metadata["bump"]
        raise "No bump specified for changeset: `#{path}`. " \
          "Please specify either major, minor or patch"
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
