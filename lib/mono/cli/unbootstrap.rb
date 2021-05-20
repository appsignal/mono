# frozen_string_literal: true

module Mono
  module Cli
    class Unbootstrap < Base
      def execute
        puts "Unbootstrapping project"
        run_hooks("unbootstrap", "pre")
        language.unbootstrap
        packages.each do |package|
          puts "# Unbootstrapping package: #{package.name} (#{package.path})"
          package.unbootstrap
        end
        run_hooks("unbootstrap", "post")
      end
    end
  end
end
