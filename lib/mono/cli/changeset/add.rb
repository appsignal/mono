# frozen_string_literal: true

require "fileutils"

module Mono
  module Cli
    class Changeset
      class Add < Base
        def execute
          if config.monorepo?
            puts "Available packages:"
            packages.each_with_index do |package, index|
              puts "#{index + 1}: #{package.name} (#{package.path})"
            end
            package_index =
              required_input("Select package 1-#{packages.length}: ").to_i
            package = packages[package_index - 1]
          else
            package = packages.first
          end

          dir = File.join(package.path, ".changesets")
          FileUtils.mkdir_p(dir)
          FileUtils.touch(File.join(dir, ".gitkeep"))
          change_description =
            required_input("Summarize the change (for changeset filename): ")
          filename = change_description.downcase.tr(" /\\", "-")
          filepath = File.join(dir, "#{filename}.md")
          bump = prompt_for_bump

          File.open(filepath, "w+") do |file|
            file.write(<<~CONTENTS)
              ---
              bump: "#{bump}"
              ---

              #{change_description}
            CONTENTS
          end
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

        def prompt_for_bump
          loop do
            input = required_input \
              "What type of semver bump is this (major/minor/patch): "
            if Mono::Changeset.supported_bump?(input)
              break input
            else
              puts "Unknown bump type `#{input}`. " \
                "Please specify supported bump type."
            end
          end
        end
      end
    end
  end
end