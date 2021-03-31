# frozen_string_literal: true

require "fileutils"

module Mono
  module Cli
    class Changeset < Base
      attr_reader :subcommand

      def initialize(options = [])
        @subcommand = options.shift
        super(options)
      end

      def execute
        case subcommand
        when "add"
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
          filename = change_description.downcase.tr(" /\\", "---")
          filepath = File.join(dir, "#{filename}.md")
          bump = required_input \
            "What type of semver bump is this (major/minor/patch): "

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
          system "$EDITOR #{filepath}" if open_editor
        when "status"
          puts "Not implemented in prototype. " \
            "But this would print the next determined version number."
          exit 1
        end
      end
    end
  end
end
