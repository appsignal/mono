# frozen_string_literal: true

require "time"

module Mono
  class Changeset
    attr_reader :path, :message

    # Sorted Hash of supported types in the changelog
    SUPPORTED_TYPES = {
      "add" => "Added",
      "change" => "Changed",
      "deprecate" => "Deprecated",
      "remove" => "Removed",
      "fix" => "Fixed",
      "security" => "Security"
    }.freeze
    # Supported changeset version bumps, sorted by biggest change. The "major"
    # change being the largest, index 0, and patch being the lowest, index 2.
    SUPPORTED_BUMPS = {
      "major" => "Major",
      "minor" => "Minor",
      "patch" => "Patch"
    }.freeze
    KNOWN_METADATA_KEYS = %w[bump type integrations].freeze
    YAML_FRONT_MATTER_REGEXP =
      /\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m

    class ValidationIssue
      def self.level(lvl) = define_method(:level) { lvl }

      def level = raise(NotImplementedError)
      def message = raise(NotImplementedError)
      def error?   = level == :error
      def warning? = level == :warning

      class NoMetadata < ValidationIssue
        level :error

        def message = "No metadata found. Please add a YAML front matter block."
      end

      class UnknownMetadataKey < ValidationIssue
        level :warning

        def initialize(key)
          super()
          @key = key
        end

        def message = "Unknown metadata key: `#{@key}`"
      end

      class MissingBump < ValidationIssue
        level :error

        def message = "Missing `bump` metadata"
      end

      class UnknownBump < ValidationIssue
        level :error

        def initialize(bump)
          super()
          @bump = bump
        end

        def message = "Unknown `bump` metadata: `#{@bump}`"
      end

      class MissingType < ValidationIssue
        level :error

        def message = "Missing `type` metadata"
      end

      class UnknownType < ValidationIssue
        level :error

        def initialize(type)
          super()
          @type = type
        end

        def message = "Unknown `type` metadata: `#{@type}`"
      end

      class MissingMessage < ValidationIssue
        level :error

        def message
          "No changeset message found. Please add a description of the change."
        end
      end
    end

    ParseResult = Struct.new(:file, :changeset, :issues) do
      def errors   = issues.select(&:error?)
      def warnings = issues.select(&:warning?)

      def valid?(warnings_as_errors: false)
        failures(warnings_as_errors).empty?
      end

      # Returns Changeset or raises InvalidChangeset.
      def valid!(warnings_as_errors: false)
        return changeset if valid?(:warnings_as_errors => warnings_as_errors)

        raise InvalidChangeset.new(file, failures(warnings_as_errors))
      end

      private

      def failures(warnings_as_errors)
        warnings_as_errors ? issues : errors
      end
    end

    class UnknownBumpTypeError < Mono::Error; end

    class InvalidChangeset < Mono::Error
      attr_reader :issues

      def initialize(file, issues)
        @file = file
        @issues = issues
        super()
      end

      def message
        formatted_issues = @issues.map { |issue| "- #{issue.message}" }
        <<~MESSAGE
          Invalid changeset detected: `#{@file}`
          Issues:
          #{formatted_issues.join("\n")}
        MESSAGE
      end
    end

    def self.supported_bump?(bump)
      SUPPORTED_BUMPS.include?(bump)
    end

    def self.supported_type?(type)
      SUPPORTED_TYPES.include?(type)
    end

    def self.parse(file)
      contents = File.read(file)
      frontmatter_matches = YAML_FRONT_MATTER_REGEXP.match(contents)
      unless frontmatter_matches
        return ParseResult.new(file, nil,
          [ValidationIssue::NoMetadata.new])
      end

      metadata = YAML.safe_load(frontmatter_matches[1])
      issues = []

      unknown = metadata.keys - KNOWN_METADATA_KEYS
      unknown.each do |key|
        issues << ValidationIssue::UnknownMetadataKey.new(key)
      end

      bump = metadata["bump"]
      if bump.to_s.empty?
        issues << ValidationIssue::MissingBump.new
      elsif !supported_bump?(bump)
        issues << ValidationIssue::UnknownBump.new(bump)
      end

      type = metadata["type"]
      if type.to_s.empty?
        issues << ValidationIssue::MissingType.new
      elsif !supported_type?(type)
        issues << ValidationIssue::UnknownType.new(type)
      end

      message = contents.sub(frontmatter_matches[0], "").strip
      issues << ValidationIssue::MissingMessage.new if message.empty?

      return ParseResult.new(file, nil, issues) if issues.any?(&:error?)

      ParseResult.new(file, new(file, metadata, message), issues)
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

    def integrations
      @metadata["integrations"]
    end

    def type
      @metadata["type"]
    end

    def type_label
      SUPPORTED_TYPES.fetch(type)
    end

    # Returns the number equivilant of the change type string. A lower number
    # is a higher change.
    # - add == 0
    # - change == 1
    # - deprecate == 2
    # - remove == 3
    # - fix == 4
    # - security == 5
    def type_index
      SUPPORTED_TYPES.keys.index type
    end

    def bump
      @metadata["bump"]
    end

    # Returns the number equivilant of the version bump string. A lower number
    # is a higher change.
    # - major == 0
    # - minor == 1
    # - patch == 2
    def bump_index
      SUPPORTED_BUMPS.keys.index @metadata["bump"]
    end

    def date
      commit = commits.first
      commit ? commit[:date] : Time.at(0)
    end

    def commits
      @commits ||=
        begin
          escaped_path = path.gsub('"', '\"')
          cmd = <<~COMMAND
            git log \
              --pretty="format:%h %H %cI" \
            --grep="\\[skip mono\\]" \
              --invert-grep \
              -- "#{escaped_path}"
          COMMAND
          git_log = `#{cmd}`
          git_log.split("\n").map do |line|
            short, long, date = line.split(" ")
            {
              :short => short,
              :long => long,
              :date => Time.parse(date)
            }
          end
        end
    end

    def remove
      FileUtils.rm path
    end
  end

  class MemoryChangeset < Changeset
    def initialize(metadata, message)
      super(nil, metadata, message)
    end

    def date
      @date ||= Time.now
    end

    def commits
      []
    end

    def remove
      # noop
    end
  end

  class DependencyBumpMemoryChangeset < MemoryChangeset
    attr_reader :dependency_name

    def initialize(dependency)
      @dependency_name = dependency.name
      message = "Update #{dependency.name} dependency to " \
        "#{dependency.next_version}."
      super({ "bump" => "patch", "type" => "change" }, message)
    end
  end
end
