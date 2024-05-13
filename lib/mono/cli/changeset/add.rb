# frozen_string_literal: true

require "fileutils"

module Mono
  module Cli
    class Changeset
      class Add < Base
        def execute
          package =
            if config.monorepo?
              prompt_for_package
            else
              packages.first
            end

          dir = File.join(package.path, ".changesets")
          FileUtils.mkdir_p(dir)
          FileUtils.touch(File.join(dir, ".gitkeep"))
          change_description =
            required_input("Summarize the change (for changeset filename): ")
          filename = change_description.downcase.gsub(/\W/, "-")
          filepath = File.join(dir, "#{filename}.md")
          type = prompt_for_type
          bump = prompt_for_bump
          metadata = {
            "bump" => bump,
            "type" => type
          }

          metadata_yml = YAML.dump(metadata)
          File.write(filepath, <<~CONTENTS)
            #{metadata_yml.strip}
            ---

            #{change_description}
          CONTENTS
          puts "Changeset file created at #{filepath}"
          open_editor = yes_or_no(
            "Do you want to open this file to add more information? (y/N): ",
            :default => "N"
          )
          if open_editor
            puts "Opening #{filepath} with editor..."
            run_command "$EDITOR #{filepath}"
          end
        end

        private

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
