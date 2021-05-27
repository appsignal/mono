# frozen_string_literal: true

module Mono
  module Languages
    module Ruby
      class Package < PackageBase
        def current_version
          @current_version ||=
            begin
              contents = read_version
              matches = VERSION_REGEX.match(contents)
              Version.parse_ruby(matches[1])
            end
        end

        def write_new_version
          contents = read_version
          new_contents =
            contents.sub(VERSION_REGEX, %(VERSION = "#{next_version}"))
          File.open(version_path, "w+") do |file|
            file.write new_contents
          end
        end

        def bootstrap_package(_options = {})
          run_command_in_package "bundle install"
        end

        def publish_package
          gem_files = fetch_gem_files_paths
          if gem_files.any?
            gem_files.each do |gem_file|
              run_command "gem push #{gem_file}"
            end
          else
            raise "No gemfiles found in `#{gem_files_dir || "."}`"
          end
        end

        def build_package
          run_command_in_package "gem build"
        end

        def test_package
          run_command_in_package "bundle exec rake test"
        end

        def clean_package
          paths = []
          files_dir = gem_files_dir
          paths << path
          paths << files_dir if files_dir
          paths << "*.gem"
          gem_files = Dir.glob(File.join(paths))
          gem_files.each do |gem_file|
            FileUtils.remove gem_file
          end
        end

        def unbootstrap_package
          run_command_in_package "rm -rf vendor/ tmp/"
        end

        private

        VERSION_REGEX = /VERSION = "(.*)"/.freeze

        def read_version
          File.read(version_path)
        end

        def version_path
          Dir.glob(package_path("lib/*/version.rb")).first
        end

        def gem_files_dir
          gem_files_dir = config.publish["gem_files_dir"]
          gem_files_dir if gem_files_dir && !gem_files_dir.strip.empty?
        end

        def fetch_gem_files_paths
          files_dir = gem_files_dir

          # Normal .gem files
          # Example: package-1.2.3.gem
          paths = []
          base_path = []
          base_path << files_dir if files_dir
          base_path << "*-#{next_version}.gem"
          paths << File.join(base_path)

          # Platform .gem files
          # Example: package-1.2.3-java.gem
          platform_path = []
          platform_path << files_dir if files_dir
          platform_path << "*-#{next_version}-*.gem"
          paths << File.join(platform_path)

          Dir.glob(paths)
        end
      end
    end
  end
end
