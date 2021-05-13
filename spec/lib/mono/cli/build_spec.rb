# frozen_string_literal: true

RSpec.describe Mono::Cli::Build do
  context "with custom command" do
    context "with single package" do
      it "runs custom command" do
        prepare_project :elixir_single
        output =
          capture_stdout do
            in_project do
              configure_command("build", "echo build")
              run_build
            end
          end

        expect(output).to include("Building package: elixir_single_project (.)")
        expect(performed_commands).to eql([
          ["/elixir_single_project", "echo build"]
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
              configure_command("build", "echo build")
              run_build
            end
          end

        project_path = "/elixir_mono_project"
        package_one_path = "#{project_path}/packages/package_one"
        package_two_path = "#{project_path}/packages/package_two"
        expect(output).to include("Building package: package_one (packages/package_one)")
        expect(output).to include("Building package: package_two (packages/package_two)")
        expect(performed_commands).to eql([
          [package_one_path, "echo build"],
          [package_two_path, "echo build"]
        ])
        expect(exit_status).to eql(0), output
      end
    end
  end

  context "with Elixir project" do
    context "with single repo" do
      it "builds the project" do
        prepare_project :elixir_single
        output =
          capture_stdout do
            in_project { run_build }
          end

        expect(output).to include("Building package: elixir_single_project (.)")
        expect(performed_commands).to eql([
          ["/elixir_single_project", "mix compile"]
        ])
        expect(exit_status).to eql(0), output
      end

      context "with hooks" do
        it "runs hooks around command" do
          prepare_project :elixir_single
          output =
            capture_stdout do
              in_project do
                add_hook("build", "pre", "echo before")
                add_hook("build", "post", "echo after")
                run_build
              end
            end

          expect(output).to include("Building package: elixir_single_project (.)")
          expect(performed_commands).to eql([
            ["/elixir_single_project", "echo before"],
            ["/elixir_single_project", "mix compile"],
            ["/elixir_single_project", "echo after"]
          ])
          expect(exit_status).to eql(0), output
        end
      end
    end

    context "with mono repo" do
      it "builds the packages" do
        prepare_project :elixir_mono
        output =
          capture_stdout do
            in_project { run_build }
          end

        expect(output).to include("Building package: package_one (packages/package_one)")
        expect(output).to include("Building package: package_two (packages/package_two)")
        expect(performed_commands).to eql([
          ["/elixir_mono_project/packages/package_one", "mix compile"],
          ["/elixir_mono_project/packages/package_two", "mix compile"]
        ])
        expect(exit_status).to eql(0), output
      end

      context "with hooks" do
        it "runs hooks around command" do
          prepare_project :elixir_mono
          output =
            capture_stdout do
              in_project do
                add_hook("build", "pre", "echo before")
                add_hook("build", "post", "echo after")
                run_build
              end
            end

          project_path = "/elixir_mono_project"
          package_one_path = "#{project_path}/packages/package_one"
          package_two_path = "#{project_path}/packages/package_two"
          expect(output).to include(
            "Building package: package_one (packages/package_one)",
            "Building package: package_two (packages/package_two)"
          )
          expect(performed_commands).to eql([
            [project_path, "echo before"],
            [package_one_path, "mix compile"],
            [package_two_path, "mix compile"],
            [project_path, "echo after"]
          ])
          expect(exit_status).to eql(0), output
        end
      end
    end
  end

  context "with Ruby project" do
    context "with single repo" do
      it "builds the project" do
        prepare_project :ruby_single
        output =
          capture_stdout do
            in_project { run_build }
          end

        expect(output).to include("Building package: ruby_single_project (.)")
        expect(performed_commands).to eql([
          ["/ruby_single_project", "gem build"]
        ])
        expect(exit_status).to eql(0), output
      end
    end

    context "with mono repo" do
      it "builds the packages" do
        prepare_project :ruby_mono
        output =
          capture_stdout do
            in_project { run_build }
          end

        expect(output).to include("Building package: package_one (packages/package_one)")
        expect(output).to include("Building package: package_two (packages/package_two)")
        expect(performed_commands).to eql([
          ["/ruby_mono_project/packages/package_one", "gem build"],
          ["/ruby_mono_project/packages/package_two", "gem build"]
        ])
        expect(exit_status).to eql(0), output
      end
    end
  end

  context "with Node.js project" do
    context "with npm" do
      context "with npm < 7" do
        pending "install new npm version"
      end

      context "with npm >= 7" do
        context "with single repo" do
          it "builds the project" do
            prepare_project :nodejs_npm_single
            output =
              capture_stdout do
                in_project { run_build }
              end

            expect(output).to include("Building package: nodejs_npm_single_project (.)")
            expect(performed_commands).to eql([
              ["/nodejs_npm_single_project", "npm run build"]
            ])
            expect(exit_status).to eql(0), output
          end

          context "without a build command configured" do
            it "skips the command for the package" do
              prepare_project :nodejs_npm_single
              output =
                capture_stdout do
                  in_project do
                    remove_script_from_package_json("build")
                    run_build
                  end
                end

              expect(output).to include(
                "Building package: nodejs_npm_single_project (.)",
                "Command not configured. Skipped command for nodejs_npm_single_project (.)"
              )
              expect(performed_commands).to eql([])
              expect(exit_status).to eql(0), output
            end
          end
        end

        context "with mono repo" do
          it "builds the project workspace" do
            prepare_project :nodejs_npm_mono
            output =
              capture_stdout do
                in_project { run_build }
              end

            project_path = "/nodejs_npm_mono_project"
            expect(output).to include(
              "Building package: package_one (packages/package_one)",
              "Building package: package_two (packages/package_two)"
            )
            expect(performed_commands).to eql([
              [project_path, "npm run build --workspace=package_one"],
              [project_path, "npm run build --workspace=package_two"]
            ])
            expect(exit_status).to eql(0), output
          end

          context "without a build command configured" do
            it "skips the command for the package" do
              prepare_project :nodejs_npm_mono
              output =
                capture_stdout do
                  in_project do
                    in_package :package_one do
                      remove_script_from_package_json("build")
                    end
                    run_build
                  end
                end

              project_path = "/nodejs_npm_mono_project"
              expect(output).to include(
                "Building package: package_one (packages/package_one)",
                "Command not configured. Skipped command for package_one (packages/package_one)",
                "Building package: package_two (packages/package_two)"
              )
              expect(performed_commands).to eql([
                [project_path, "npm run build --workspace=package_two"]
              ])
              expect(exit_status).to eql(0), output
            end
          end
        end
      end
    end

    context "with yarn" do
      context "with yarn < 1" do
        pending "install new yarn version"
      end

      context "with yarn >= 1" do
        context "with single repo" do
          it "builds the project" do
            prepare_project :nodejs_yarn_single
            output =
              capture_stdout do
                in_project { run_build }
              end

            expect(output).to include("Building package: nodejs_yarn_single_project (.)")
            expect(performed_commands).to eql([
              ["/nodejs_yarn_single_project", "yarn run build"]
            ])
            expect(exit_status).to eql(0), output
          end
        end

        context "with mono repo" do
          it "builds the project workspace" do
            prepare_project :nodejs_yarn_mono
            output =
              capture_stdout do
                in_project { run_build }
              end

            project_path = "/nodejs_yarn_mono_project"
            expect(output).to include(
              "Building package: package_one (packages/package_one)",
              "Building package: package_two (packages/package_two)"
            )
            expect(performed_commands).to eql([
              [project_path, "yarn workspace package_one run build"],
              [project_path, "yarn workspace package_two run build"]
            ])
            expect(exit_status).to eql(0), output
          end
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
            in_project { run_build }
          end

        expect(output).to include("UnknownLanguageError: Unknown language configured"), output
        expect(exit_status).to eql(1), output
      end
    end

    context "with mono repo" do
      it "builds the packages" do
        prepare_project :unknown_mono
        output =
          capture_stdout do
            in_project { run_build }
          end

        expect(output).to include("UnknownLanguageError: Unknown language configured"), output
        expect(exit_status).to eql(1), output
      end
    end
  end

  def run_build(args = [])
    Mono::Cli::Wrapper.new(["build"] + args).execute
  end
end
