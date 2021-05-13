# frozen_string_literal: true

RSpec.describe Mono::Cli::Test do
  context "with custom command" do
    context "with single package" do
      it "runs custom command" do
        prepare_project :elixir_single
        output =
          capture_stdout do
            in_project do
              configure_command("test", "echo test")
              run_test
            end
          end

        expect(output).to include("Testing package: elixir_single_project (.)")
        expect(performed_commands).to eql([
          ["/elixir_single_project", "echo test"]
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
              configure_command("test", "echo test")
              run_test
            end
          end

        project_path = "/elixir_mono_project"
        package_one_path = "#{project_path}/packages/package_one"
        package_two_path = "#{project_path}/packages/package_two"
        expect(output).to include("Testing package: package_one (packages/package_one)")
        expect(output).to include("Testing package: package_two (packages/package_two)")
        expect(performed_commands).to eql([
          [package_one_path, "echo test"],
          [package_two_path, "echo test"]
        ])
        expect(exit_status).to eql(0), output
      end
    end
  end

  context "with Elixir project" do
    context "with single repo" do
      it "tests the project" do
        prepare_project :elixir_single
        output =
          capture_stdout do
            in_project { run_test }
          end

        expect(output).to include("Testing package: elixir_single_project (.)")
        expect(performed_commands).to eql([
          ["/elixir_single_project", "mix test"]
        ])
        expect(exit_status).to eql(0), output
      end

      context "with hooks" do
        it "runs hooks around command" do
          prepare_project :elixir_single
          output =
            capture_stdout do
              in_project do
                add_hook("test", "pre", "echo before")
                add_hook("test", "post", "echo after")
                run_test
              end
            end

          expect(output).to include("Testing package: elixir_single_project (.)")
          expect(performed_commands).to eql([
            ["/elixir_single_project", "echo before"],
            ["/elixir_single_project", "mix test"],
            ["/elixir_single_project", "echo after"]
          ])
          expect(exit_status).to eql(0), output
        end
      end
    end

    context "with mono repo" do
      it "tests the packages" do
        prepare_project :elixir_mono
        output =
          capture_stdout do
            in_project { run_test }
          end

        project_path = "/elixir_mono_project"
        package_one_path = "#{project_path}/packages/package_one"
        package_two_path = "#{project_path}/packages/package_two"
        expect(output).to include("Testing package: package_one (packages/package_one)")
        expect(output).to include("Testing package: package_two (packages/package_two)")
        expect(performed_commands).to eql([
          [package_one_path, "mix test"],
          [package_two_path, "mix test"]
        ])
        expect(exit_status).to eql(0), output
      end

      context "with hooks" do
        it "runs hooks around command" do
          prepare_project :elixir_mono
          output =
            capture_stdout do
              in_project do
                add_hook("test", "pre", "echo before")
                add_hook("test", "post", "echo after")
                run_test
              end
            end

          project_path = "/elixir_mono_project"
          package_one_path = "#{project_path}/packages/package_one"
          package_two_path = "#{project_path}/packages/package_two"
          expect(output).to include(
            "Testing package: package_one (packages/package_one)",
            "Testing package: package_two (packages/package_two)"
          )
          expect(performed_commands).to eql([
            [project_path, "echo before"],
            [package_one_path, "mix test"],
            [package_two_path, "mix test"],
            [project_path, "echo after"]
          ])
          expect(exit_status).to eql(0), output
        end
      end
    end
  end

  context "with Ruby project" do
    context "with single repo" do
      it "tests the project" do
        prepare_project :ruby_single
        output =
          capture_stdout do
            in_project { run_test }
          end

        expect(output).to include("Testing package: ruby_single_project (.)")
        expect(performed_commands).to eql([
          ["/ruby_single_project", "bundle exec rake test"]
        ])
        expect(exit_status).to eql(0), output
      end
    end

    context "with mono repo" do
      it "tests the packages" do
        prepare_project :ruby_mono
        output =
          capture_stdout do
            in_project { run_test }
          end

        project_path = "/ruby_mono_project"
        package_one_path = "#{project_path}/packages/package_one"
        package_two_path = "#{project_path}/packages/package_two"
        expect(output).to include("Testing package: package_one (packages/package_one)")
        expect(output).to include("Testing package: package_two (packages/package_two)")
        expect(performed_commands).to eql([
          [package_one_path, "bundle exec rake test"],
          [package_two_path, "bundle exec rake test"]
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
          it "tests the project" do
            prepare_project :nodejs_npm_single
            output =
              capture_stdout do
                in_project { run_test }
              end

            expect(output).to include("Testing package: nodejs_npm_single_project (.)")
            expect(output).to_not include(
              "Command not configured. Skipped command for nodejs_npm_single_project (.)"
            )
            expect(performed_commands).to eql([
              ["/nodejs_npm_single_project", "npm run test"]
            ])
            expect(exit_status).to eql(0), output
          end

          context "without a test command configured" do
            it "skips the command for the package" do
              prepare_project :nodejs_npm_single
              output =
                capture_stdout do
                  in_project do
                    remove_script_from_package_json("test")
                    run_test
                  end
                end

              expect(output).to include(
                "Testing package: nodejs_npm_single_project (.)",
                "Command not configured. Skipped command for nodejs_npm_single_project (.)"
              )
              expect(performed_commands).to eql([])
              expect(exit_status).to eql(0), output
            end
          end
        end

        context "with mono repo" do
          it "tests the project workspace" do
            prepare_project :nodejs_npm_mono
            output =
              capture_stdout do
                in_project { run_test }
              end

            project_path = "/nodejs_npm_mono_project"
            expect(output).to include(
              "Testing package: package_one (packages/package_one)",
              "Testing package: package_two (packages/package_two)"
            )
            expect(performed_commands).to eql([
              [project_path, "npm run test --workspace=package_one"],
              [project_path, "npm run test --workspace=package_two"]
            ])
            expect(exit_status).to eql(0), output
          end

          context "without a test command configured" do
            it "skips the command for the package" do
              prepare_project :nodejs_npm_mono
              output =
                capture_stdout do
                  in_project do
                    in_package :package_one do
                      remove_script_from_package_json("test")
                    end
                    run_test
                  end
                end

              project_path = "/nodejs_npm_mono_project"
              expect(output).to include(
                "Testing package: package_one (packages/package_one)",
                "Command not configured. Skipped command for package_one (packages/package_one)",
                "Testing package: package_two (packages/package_two)"
              )
              expect(performed_commands).to eql([
                [project_path, "npm run test --workspace=package_two"]
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
          it "tests the project" do
            prepare_project :nodejs_yarn_single
            output =
              capture_stdout do
                in_project { run_test }
              end

            expect(output).to include("Testing package: nodejs_yarn_single_project (.)")
            expect(performed_commands).to eql([
              ["/nodejs_yarn_single_project", "yarn run test"]
            ])
            expect(exit_status).to eql(0), output
          end
        end

        context "with mono repo" do
          it "tests the project workspace" do
            prepare_project :nodejs_yarn_mono
            output =
              capture_stdout do
                in_project { run_test }
              end

            project_path = "/nodejs_yarn_mono_project"
            expect(output).to include(
              "Testing package: package_one (packages/package_one)",
              "Testing package: package_two (packages/package_two)"
            )
            expect(performed_commands).to eql([
              [project_path, "yarn workspace package_one run test"],
              [project_path, "yarn workspace package_two run test"]
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
            in_project { run_test }
          end

        expect(output).to include("UnknownLanguageError: Unknown language configured"), output
        expect(exit_status).to eql(1), output
      end
    end

    context "with mono repo" do
      it "tests the packages" do
        prepare_project :unknown_mono
        output =
          capture_stdout do
            in_project { run_test }
          end

        expect(output).to include("UnknownLanguageError: Unknown language configured"), output
        expect(exit_status).to eql(1), output
      end
    end
  end

  def run_test(args = [])
    Mono::Cli::Wrapper.new(["test"] + args).execute
  end
end
