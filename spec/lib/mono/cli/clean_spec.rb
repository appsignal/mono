# frozen_string_literal: true

RSpec.describe Mono::Cli::Clean do
  context "with custom command" do
    context "with single package" do
      it "runs custom command" do
        prepare_project :elixir_single
        output =
          capture_stdout do
            in_project do
              configure_command("clean", "echo clean")
              run_clean
            end
          end

        expect(output).to include("Cleaning package: elixir_single_project (.)")
        expect(performed_commands).to eql([
          ["/elixir_single_project", "echo clean"]
        ])
        expect(exit_status).to eql(0), output
      end
    end

    context "with mono repo" do
      it "runs custom command" do
        prepare_project :elixir_mono
        output =
          capture_stdout do
            in_project do
              configure_command("clean", "echo clean")
              run_clean
            end
          end

        project_path = "/elixir_mono_project"
        package_one_path = "#{project_path}/packages/package_one"
        package_two_path = "#{project_path}/packages/package_two"
        expect(output).to include("Cleaning package: package_one (packages/package_one)")
        expect(output).to include("Cleaning package: package_two (packages/package_two)")
        expect(performed_commands).to eql([
          [package_one_path, "echo clean"],
          [package_two_path, "echo clean"]
        ])
        expect(exit_status).to eql(0), output
      end
    end
  end

  context "with Elixir project" do
    context "with single repo" do
      it "cleans the project" do
        prepare_project :elixir_single
        output =
          capture_stdout do
            in_project { run_clean }
          end

        expect(output).to include("Cleaning package: elixir_single_project (.)")
        expect(performed_commands).to eql([
          ["/elixir_single_project", "rm -rf _build"]
        ])
        expect(exit_status).to eql(0), output
      end

      context "with hooks" do
        it "runs hooks around command" do
          prepare_project :elixir_single
          output =
            capture_stdout do
              in_project do
                add_hook("clean", "pre", "echo before")
                add_hook("clean", "post", "echo after")
                run_clean
              end
            end

          expect(output).to include("Cleaning package: elixir_single_project (.)")
          expect(performed_commands).to eql([
            ["/elixir_single_project", "echo before"],
            ["/elixir_single_project", "rm -rf _build"],
            ["/elixir_single_project", "echo after"]
          ])
          expect(exit_status).to eql(0), output
        end
      end
    end

    context "with mono repo" do
      it "cleans the packages" do
        prepare_project :elixir_mono
        output =
          capture_stdout do
            in_project { run_clean }
          end

        expect(output).to include("Cleaning package: package_one (packages/package_one)")
        expect(output).to include("Cleaning package: package_two (packages/package_two)")
        expect(performed_commands).to eql([
          ["/elixir_mono_project/packages/package_one", "rm -rf _build"],
          ["/elixir_mono_project/packages/package_two", "rm -rf _build"]
        ])
        expect(exit_status).to eql(0), output
      end

      context "with hooks" do
        it "runs hooks around command" do
          prepare_project :elixir_mono
          output =
            capture_stdout do
              in_project do
                add_hook("clean", "pre", "echo before")
                add_hook("clean", "post", "echo after")
                run_clean
              end
            end

          project_path = "/elixir_mono_project"
          package_one_path = "#{project_path}/packages/package_one"
          package_two_path = "#{project_path}/packages/package_two"
          expect(output).to include(
            "Cleaning package: package_one (packages/package_one)",
            "Cleaning package: package_two (packages/package_two)"
          )
          expect(performed_commands).to eql([
            [project_path, "echo before"],
            [package_one_path, "rm -rf _build"],
            [package_two_path, "rm -rf _build"],
            [project_path, "echo after"]
          ])
          expect(exit_status).to eql(0), output
        end
      end

      context "with only one package selected" do
        it "only cleans the selected package" do
          prepare_project :elixir_mono
          output =
            capture_stdout do
              in_project do
                run_clean(["--package", "package_one"])
              end
            end

          project_path = "/elixir_mono_project"
          package_one_path = "#{project_path}/packages/package_one"
          expect(output).to include(
            "Cleaning package: package_one (packages/package_one)"
          ), output
          expect(output).to_not include(
            "Cleaning package: package_two (packages/package_two)"
          ), output
          expect(performed_commands).to eql([
            [package_one_path, "rm -rf _build"]
          ])
          expect(exit_status).to eql(0), output
        end
      end

      context "with multiple packages selected" do
        it "cleans the selected packages" do
          prepare_project :elixir_mono
          output =
            capture_stdout do
              in_project do
                run_clean(["--package", "package_one,package_two"])
              end
            end

          project_path = "/elixir_mono_project"
          package_one_path = "#{project_path}/packages/package_one"
          package_two_path = "#{project_path}/packages/package_two"
          expect(output).to include(
            "Cleaning package: package_one (packages/package_one)",
            "Cleaning package: package_two (packages/package_two)"
          ), output
          expect(performed_commands).to eql([
            [package_one_path, "rm -rf _build"],
            [package_two_path, "rm -rf _build"]
          ])
          expect(exit_status).to eql(0), output
        end
      end

      context "with unknown packages selected" do
        it "exits with an error" do
          prepare_project :elixir_mono
          output =
            capture_stdout do
              in_project do
                run_clean(["--package", "package_one,package_three"])
              end
            end

          expect(output).to include(
            "Mono::PackageNotFound: The package with the name `package_three` could not be found."
          ), output
          expect(performed_commands).to eql([])
          expect(exit_status).to eql(1), output
        end
      end
    end
  end

  context "with Ruby project" do
    context "with single repo" do
      it "cleans the project" do
        prepare_project :ruby_single
        gem_file1 = "test-1.0.0.gem"
        gem_file2 = "test-1.0.1.gem"
        output =
          capture_stdout do
            in_project do
              FileUtils.touch gem_file1
              FileUtils.touch gem_file2
              run_clean
            end
          end

        expect(output).to include("Cleaning package: ruby_single_project (.)")
        in_project do
          expect(File.exist?(gem_file1)).to be_falsy
          expect(File.exist?(gem_file2)).to be_falsy
        end
        expect(performed_commands).to eql([])
        expect(exit_status).to eql(0), output
      end
    end

    context "with mono repo" do
      it "cleans the packages" do
        prepare_project :ruby_mono
        gem_file1 = "test-1.0.0.gem"
        gem_file2 = "test-1.0.1.gem"
        output =
          capture_stdout do
            in_project do
              in_package "package_one" do
                FileUtils.touch gem_file1
                FileUtils.touch gem_file2
              end
              in_package "package_two" do
                FileUtils.touch gem_file1
                FileUtils.touch gem_file2
              end
              run_clean
            end
          end

        expect(output).to include("Cleaning package: package_one (packages/package_one)")
        expect(output).to include("Cleaning package: package_two (packages/package_two)")
        in_project do
          in_package "package_one" do
            expect(File.exist?(gem_file1)).to be_falsy
            expect(File.exist?(gem_file2)).to be_falsy
          end
          in_package "package_two" do
            expect(File.exist?(gem_file1)).to be_falsy
            expect(File.exist?(gem_file2)).to be_falsy
          end
        end
        expect(performed_commands).to eql([])
        expect(exit_status).to eql(0), output
      end
    end
  end

  context "with Node.js project" do
    context "with npm" do
      context "with single repo" do
        it "cleans the project" do
          prepare_project :nodejs_npm_single
          output =
            capture_stdout do
              in_project { run_clean }
            end

          expect(output).to include("Cleaning package: nodejs_npm_single_project (.)")
          expect(performed_commands).to eql([
            ["/nodejs_npm_single_project", "npm run clean"]
          ])
          expect(exit_status).to eql(0), output
        end
      end

      context "with mono repo" do
        it "cleans the project workspace" do
          prepare_project :nodejs_npm_mono
          output =
            capture_stdout do
              in_project { run_clean }
            end

          project_path = "/nodejs_npm_mono_project"
          expect(output).to include(
            "Cleaning package: package_one (packages/package_one)",
            "Cleaning package: package_two (packages/package_two)"
          )
          expect(performed_commands).to eql([
            [project_path, "npm run clean --workspace=package_one"],
            [project_path, "npm run clean --workspace=package_two"]
          ])
          expect(exit_status).to eql(0), output
        end
      end
    end

    context "with yarn" do
      context "with single repo" do
        it "cleans the project" do
          prepare_project :nodejs_yarn_single
          output =
            capture_stdout do
              in_project { run_clean }
            end

          expect(output).to include("Cleaning package: nodejs_yarn_single_project (.)")
          expect(performed_commands).to eql([
            ["/nodejs_yarn_single_project", "yarn run clean"]
          ])
          expect(exit_status).to eql(0), output
        end
      end

      context "with mono repo" do
        it "cleans the project workspace" do
          prepare_project :nodejs_yarn_mono
          output =
            capture_stdout do
              in_project { run_clean }
            end

          project_path = "/nodejs_yarn_mono_project"
          expect(output).to include(
            "Cleaning package: package_one (packages/package_one)",
            "Cleaning package: package_two (packages/package_two)"
          )
          expect(performed_commands).to eql([
            [project_path, "yarn workspace package_one run clean"],
            [project_path, "yarn workspace package_two run clean"]
          ])
          expect(exit_status).to eql(0), output
        end
      end
    end
  end

  context "with unknown language project" do
    context "with single repo" do
      it "prints an error and exits" do
        prepare_project :unknown_single
        output =
          capture_stdout do
            in_project { run_clean }
          end

        expect(output).to include("UnknownLanguageError: Unknown language configured"), output
        expect(exit_status).to eql(1), output
      end
    end

    context "with mono repo" do
      it "cleans the packages" do
        prepare_project :unknown_mono
        output =
          capture_stdout do
            in_project { run_clean }
          end

        expect(output).to include("UnknownLanguageError: Unknown language configured"), output
        expect(exit_status).to eql(1), output
      end
    end
  end

  def run_clean(args = [])
    Mono::Cli::Wrapper.new(["clean"] + args).execute
  end
end
