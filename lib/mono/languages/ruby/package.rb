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
              Gem::Version.new(matches[1])
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

        def bootstrap_package
          run_command "bundle install"
        end

        def publish_package
          pkg_path = config.publish.fetch("gem_files")
          if pkg_path
            gem_files = Dir.glob(pkg_path)
            if gem_files.any?
              gem_files.each do |gem_file|
                run_command "gem push #{gem_file}"
              end
            else
              raise "No gemfiles found for `#{pkg_path}`"
            end
          else
            # Normal gem push
            raise "Ruby normal gem push not implemented"
          end
        end

        def build_package
          run_command "gem build"
        end

        def test_package
          run_command "bundle exec rake test"
        end

        def clean_package
          run_command "rm -rf vendor/ tmp/"
        end

        private

        VERSION_REGEX = /VERSION = "(.*)"/.freeze

        def read_version
          File.read(version_path)
        end

        def version_path
          # TODO: Dynamically find version.rb file rather than a hardcoded path?
          File.join(path, "lib/appsignal/version.rb")
        end
      end
    end
  end
end
