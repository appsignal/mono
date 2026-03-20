# frozen_string_literal: true

module Mono
  class Changeset
    class ValidationIssue
      class MissingIntegration < ValidationIssue
        level :error

        def initialize(allowed)
          super()
          @allowed = allowed
        end

        def message
          "Missing `integrations` metadata. " \
            "Allowed values: all, none, #{@allowed.join(", ")}"
        end
      end

      class AllCombinedWithOthers < ValidationIssue
        level :error

        def message = '"all" cannot be combined with other integrations'
      end

      class NoneCombinedWithOthers < ValidationIssue
        level :error

        def message = '"none" cannot be combined with other integrations'
      end

      class UnknownIntegrations < ValidationIssue
        level :error

        def initialize(unknowns, allowed)
          super()
          @unknowns = unknowns
          @allowed = allowed
        end

        def message
          "Unknown integration(s): #{@unknowns.map(&:inspect).join(", ")}. " \
            "Allowed values: all, none, #{@allowed.join(", ")}"
        end
      end

      class UnexpectedIntegrations < ValidationIssue
        level :warning

        def message
          "Has `integrations` metadata but project has " \
            "no integrations configured"
        end
      end
    end
  end
end

module Mono
  module Cli
    class Changeset
      class Validate < Base
        ValidationIssue = Mono::Changeset::ValidationIssue
        def execute
          invalid = []
          warned = []
          total = []

          packages.each do |package|
            changeset_dir = File.join(package.path, ".changesets")
            next unless Dir.exist?(changeset_dir)

            Dir.glob(File.join(changeset_dir, "*.md")).each do |file|
              result = validate_changeset_file(file)
              print_file_validation(result,
                :warnings_as_errors => warnings_as_errors?)

              total << file
              if !result.valid?(:warnings_as_errors => warnings_as_errors?)
                invalid << file
              elsif result.warnings.any?
                warned << file
              end
            end
          end

          total_count = total.length
          total_noun = total_count == 1 ? "changeset" : "changesets"

          if invalid.any?
            invalid_count = invalid.length
            invalid_noun = invalid_count == 1 ? "changeset" : "changesets"
            invalid_verb = invalid_count == 1 ? "is" : "are"
            parts = [
              "Found #{total_count} #{total_noun}.",
              "#{invalid_count} #{invalid_noun} #{invalid_verb} invalid."
            ]
            parts << warned_note(warned) if warned.any?
            puts parts.join(" ")
            exit 1
          else
            parts = []
            if total_count.positive?
              parts << "Found #{total_count} #{total_noun}."
            end
            parts << "All changesets are valid."
            parts << warned_note(warned) if warned.any?
            puts parts.join(" ")
          end
        end

        def warned_note(warned)
          count = warned.length
          noun = count == 1 ? "changeset" : "changesets"
          verb = count == 1 ? "has" : "have"
          "#{count} valid #{noun} #{verb} warnings."
        end

        def print_file_validation(result, warnings_as_errors: false)
          valid = result.valid?(:warnings_as_errors => warnings_as_errors)
          label = valid ? "Valid" : "Invalid"
          counts = issue_count_suffix(result.errors.length,
            result.warnings.length)
          puts "#{label}: #{result.file}#{counts}"
          result.issues.each do |i|
            puts "- [#{i.level.to_s.capitalize}] #{i.message}"
          end
          puts
        end

        def validate_changeset_file(filepath)
          result = Mono::Changeset.parse(filepath)
          return result unless result.valid?

          Mono::Changeset::ParseResult.new(
            filepath, result.changeset,
            result.issues + integration_issues(result.changeset)
          )
        end

        private

        def integration_issues(changeset)
          if config.config?("integrations")
            allowed = config.config("integrations")
            value = changeset.integrations

            unless value
              return [ValidationIssue::MissingIntegration.new(allowed)]
            end

            values = Array(value)
            combination_issues = []

            if values.include?("all") && values.length > 1
              combination_issues << ValidationIssue::AllCombinedWithOthers.new
            end

            if values.include?("none") && values.length > 1
              combination_issues << ValidationIssue::NoneCombinedWithOthers.new
            end

            return combination_issues if combination_issues.any?

            return [] if [["all"], ["none"]].include?(values)

            unknowns = values - allowed
            return [] unless unknowns.any?

            [ValidationIssue::UnknownIntegrations.new(unknowns, allowed)]
          else
            return [] unless changeset.integrations

            [ValidationIssue::UnexpectedIntegrations.new]
          end
        end

        def warnings_as_errors?
          options[:warnings_as_errors] == true
        end

        def issue_count_suffix(error_count, warning_count)
          parts = []
          if error_count.positive?
            parts << "#{error_count} #{error_count == 1 ? "error" : "errors"}"
          end
          if warning_count.positive?
            noun = warning_count == 1 ? "warning" : "warnings"
            parts << "#{warning_count} #{noun}"
          end
          parts.empty? ? "" : " (#{parts.join(", ")})"
        end
      end
    end
  end
end
