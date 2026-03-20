# frozen_string_literal: true

require "fileutils"

module Mono
  module Cli
    class Changeset
      class Add < Base # rubocop:disable Metrics/ClassLength
        NON_INTERACTIVE_FLAGS = [:type, :bump, :integration, :packages].freeze

        def execute
          validate_non_interactive_flags!
          package = resolve_package

          dir = File.join(package.path, ".changesets")
          FileUtils.mkdir_p(dir)
          FileUtils.touch(File.join(dir, ".gitkeep"))

          change_description = resolve_change_description
          filename = Utils.normalize_filename(change_description)
          filepath = File.join(dir, "#{filename}.md")

          type = resolve_type
          bump = resolve_bump

          metadata = {
            "bump" => bump,
            "type" => type
          }
          integrations = resolve_integrations
          metadata["integrations"] = integrations if integrations

          body = resolve_body(change_description)

          metadata_yml = YAML.dump(metadata)
          File.write(filepath, <<~CONTENTS)
            #{metadata_yml.strip}
            ---

            #{body}
          CONTENTS
          puts "Changeset file created at #{filepath}"

          maybe_open_editor(filepath)
        end

        private

        def non_interactive?
          options.key?(:message)
        end

        def resolve_package
          return resolve_package_non_interactive if non_interactive?

          config.monorepo? ? prompt_for_package : packages.first
        end

        def resolve_change_description
          return options[:message].first if non_interactive?

          required_input("Summarize the change (for changeset filename): ")
        end

        def resolve_type
          return resolve_type_non_interactive if non_interactive?

          prompt_for_type
        end

        def resolve_bump
          return resolve_bump_non_interactive if non_interactive?

          prompt_for_bump
        end

        def resolve_integrations
          return resolve_integrations_non_interactive if non_interactive?

          prompt_for_integrations
        end

        def resolve_body(change_description)
          return join_messages(options[:message]) if non_interactive?

          change_description
        end

        def maybe_open_editor(filepath)
          return if non_interactive?

          open_editor = yes_or_no(
            "Do you want to open this file to add more information? (y/N): ",
            :default => "N"
          )
          return unless open_editor

          loop do
            puts "Opening #{filepath} with editor..."
            run_command "$EDITOR #{filepath}"

            validator = Validate.new(options)
            result = validator.validate_changeset_file(filepath)
            break if result.issues.empty?

            validator.print_file_validation(result)

            edit_again = yes_or_no(
              "Do you want to edit the file again? (y/N): ",
              :default => "N"
            )
            unless edit_again
              exit 1 if result.errors.any?
              break
            end
          end
        end

        def join_messages(messages)
          messages.map { |m| m.end_with?(".") ? m : "#{m}." }.join(" ")
        end

        def validate_non_interactive_flags!
          return if non_interactive?

          present = NON_INTERACTIVE_FLAGS.select { |k| options.key?(k) }
          return if present.empty?

          flag_names = present.map do |k|
            k == :packages ? "--package" : "--#{k}"
          end.join(", ")
          exit_cli \
            "#{flag_names} provided without --message.\n" \
              "Non-interactive flags require --message / -m to be set."
        end

        def resolve_package_non_interactive
          if !config.monorepo? && options.key?(:packages)
            exit_cli "--package is not supported for single-package projects."
          end
          if config.monorepo? && packages.length != 1
            exit_cli \
              "--package is required in non-interactive mode for monorepos.\n" \
                "Available packages: #{packages.map(&:name).join(", ")}"
          end
          packages.first
        end

        def resolve_type_non_interactive
          type = options[:type]
          unless type && Mono::Changeset.supported_type?(type)
            allowed = Mono::Changeset::SUPPORTED_TYPES.keys.join(", ")
            exit_cli \
              "--type is required in non-interactive mode.\n" \
                "Allowed values: #{allowed}"
          end
          type
        end

        def resolve_bump_non_interactive
          bump = options[:bump]
          unless bump && Mono::Changeset.supported_bump?(bump)
            allowed = Mono::Changeset::SUPPORTED_BUMPS.keys.join(", ")
            exit_cli \
              "--bump is required in non-interactive mode.\n" \
                "Allowed values: #{allowed}"
          end
          bump
        end

        def resolve_integrations_non_interactive
          integration_options = fetch_integration_options
          if !integration_options && options.key?(:integration)
            exit_cli \
              "--integration was provided but this " \
                "project has no integrations configured."
          end
          return unless integration_options

          raw = options[:integration]
          unless raw
            exit_cli \
              "--integration is required in non-interactive mode " \
                "because this project has integrations configured.\n" \
                "Allowed values: all, none, #{integration_options.join(", ")}"
          end

          integrations_list = raw.split(",").map(&:strip).reject(&:empty?)
          if integrations_list.include?("all")
            if integrations_list.length > 1
              exit_cli "\"all\" cannot be combined with other integrations."
            end
            return "all"
          end
          if integrations_list.include?("none")
            if integrations_list.length > 1
              exit_cli "\"none\" cannot be combined with other integrations."
            end
            return "none"
          end

          unknowns = integrations_list - integration_options
          if unknowns.any?
            exit_cli \
              "Unknown integration(s): " \
                "#{unknowns.map(&:inspect).join(", ")}.\n" \
                "Allowed values: all, none, #{integration_options.join(", ")}"
          end

          return integrations_list.first if integrations_list.length == 1

          integrations_list
        end

        def prompt_for_package
          loop do
            puts "Available packages:"
            packages.each_with_index do |package, index|
              puts "#{index + 1}: #{package.name} (#{package.path})"
            end
            package_index =
              required_input("Select package 1-#{packages.length}: ").to_i
            package_index = parse_number(package_index)
            if package_index&.positive?
              package = packages[package_index - 1]
              break package if package
            end

            puts "Unknown package selected. Please select package."
          end
        end

        def prompt_for_type
          types = Mono::Changeset::SUPPORTED_TYPES.to_a
          loop do
            puts "What type of change is this?"
            type = prompt_options("Select change type", types)
            return type if type

            puts "Unknown type selected. Please select a type."
          end
        end

        def prompt_for_bump
          bumps = Mono::Changeset::SUPPORTED_BUMPS.to_a
          loop do
            puts "What type of semver bump is this?"
            bump = prompt_options("Select bump", bumps)
            return bump if bump

            puts "Unknown bump type `#{bump}`. " \
              "Please select a supported bump type."
          end
        end

        def prompt_for_integrations
          integration_options = fetch_integration_options
          return unless integration_options

          loop do # rubocop:disable Metrics/BlockLength
            integrations = required_input(
              "For which integrations is this change? " \
                "(all, none, #{integration_options.join(", ")}): "
            )

            integrations_list = integrations
              .split(",")
              .map(&:strip)
              .reject(&:empty?)
            next if integrations_list.empty?

            if integrations_list.include?("all")
              if integrations_list.length > 1
                puts "\"all\" cannot be combined with other " \
                  "integrations. Please try again."
                next
              end
              return "all"
            end
            if integrations_list.include?("none")
              if integrations_list.length > 1
                puts "\"none\" cannot be combined with other " \
                  "integrations. Please try again."
                next
              end
              return "none"
            end

            unknowns = integrations_list - integration_options
            if unknowns.any?
              puts "Unknown integration entered: " \
                "#{unknowns.map(&:inspect).join(", ")}. Please try again."
            elsif integrations_list.length == 1
              return integrations_list.first
            else
              return integrations_list
            end
          end
        end

        def unknown_integrations(integrations)
          known_integrations = fetch_integration_options
          integrations.reject do |integration|
            known_integrations.include?(integration)
          end
        end

        def fetch_integration_options
          @config.config("integrations") if @config.config?("integrations")
        end

        def prompt_options(prompt, options)
          options.each_with_index do |(_value, label), index|
            puts "#{index + 1}: #{label}"
          end
          option_index = required_input("#{prompt} 1-#{options.length}: ")
          option_index = parse_number(option_index)
          if option_index&.positive?
            option = options[option_index - 1]&.first
            return option if option
          end
        end

        def parse_number(string)
          Integer(string)
        rescue ArgumentError
          # Do nothing, invalid value
        end
      end
    end
  end
end
