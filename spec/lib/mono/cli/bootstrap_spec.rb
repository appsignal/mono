# frozen_string_literal: true

RSpec.describe Mono::Cli::Bootstrap do
  context "with custom command" do
    context "with single package" do
      it "runs custom command" do
        prepare_project :elixir_single
        output =
          capture_stdout do
            in_project do
              configure_command("bootstrap", "echo bootstrap")
              run_bootstrap
            end
          end

        expect(output).to include("Bootstrapping package: elixir_single_project (.)")
        expect(performed_commands).to eql([
          ["/elixir_single_project", "echo bootstrap"]
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
              configure_command("bootstrap", "echo bootstrap")
              run_bootstrap
            end
          end

        project_path = "/elixir_mono_project"
        package_one_path = "#{project_path}/packages/package_one"
        package_two_path = "#{project_path}/packages/package_two"
        expect(output).to include("Bootstrapping package: package_one (packages/package_one)")
        expect(output).to include("Bootstrapping package: package_two (packages/package_two)")
        expect(performed_commands).to eql([
          [package_one_path, "echo bootstrap"],
          [package_two_path, "echo bootstrap"]
        ])
        expect(exit_status).to eql(0), output
      end
    end
  end

  context "with Elixir project" do
    context "with single repo" do
      it "bootstraps the project" do
        prepare_project :elixir_single
        output =
          capture_stdout do
            in_project { run_bootstrap }
          end

        expect(output).to include("Bootstrapping package: elixir_single_project (.)")
        expect(performed_commands).to eql([
          ["/elixir_single_project", "mix deps.get"]
        ])
        expect(exit_status).to eql(0), output
      end

      context "with hooks" do
        it "runs hooks around command" do
          prepare_project :elixir_single
          output =
            capture_stdout do
              in_project do
                add_hook("bootstrap", "pre", "echo before")
                add_hook("bootstrap", "post", "echo after")
                run_bootstrap
              end
            end

          project_path = "/elixir_single_project"
          expect(output).to include("Bootstrapping package: elixir_single_project (.)")
          expect(performed_commands).to eql([
            [project_path, "echo before"],
            [project_path, "mix deps.get"],
            [project_path, "echo after"]
          ])
          expect(exit_status).to eql(0), output
        end
      end
    end

    context "with mono repo" do
      it "bootstraps the packages" do
        prepare_project :elixir_mono
        output =
          capture_stdout do
            in_project { run_bootstrap }
          end

        project_path = "/elixir_mono_project"
        package_one_path = "#{project_path}/packages/package_one"
        package_two_path = "#{project_path}/packages/package_two"
        expect(output).to include(
          "Bootstrapping package: package_one (packages/package_one)",
          "Bootstrapping package: package_two (packages/package_two)"
        )
        expect(performed_commands).to eql([
          [package_one_path, "mix deps.get"],
          [package_two_path, "mix deps.get"]
        ])
        expect(exit_status).to eql(0), output
      end

      context "with hooks" do
        it "runs hooks around command" do
          prepare_project :elixir_mono
          output =
            capture_stdout do
              in_project do
                add_hook("bootstrap", "pre", "echo before")
                add_hook("bootstrap", "post", "echo after")
                run_bootstrap
              end
            end

          project_path = "/elixir_mono_project"
          package_one_path = "#{project_path}/packages/package_one"
          package_two_path = "#{project_path}/packages/package_two"
          expect(output).to include(
            "Bootstrapping package: package_one (packages/package_one)",
            "Bootstrapping package: package_two (packages/package_two)"
          )
          expect(performed_commands).to eql([
            [project_path, "echo before"],
            [package_one_path, "mix deps.get"],
            [package_two_path, "mix deps.get"],
            [project_path, "echo after"]
          ])
          expect(exit_status).to eql(0), output
        end
      end
    end
  end

  context "with Ruby project" do
    context "with single repo" do
      it "bootstraps the project" do
        prepare_project :ruby_single
        output =
          capture_stdout do
            in_project { run_bootstrap }
          end

        expect(output).to include("Bootstrapping package: ruby_single_project (.)")
        expect(performed_commands).to eql([
          ["/ruby_single_project", "bundle install"]
        ])
        expect(exit_status).to eql(0), output
      end
    end

    context "with mono repo" do
      it "bootstraps the packages" do
        prepare_project :ruby_mono
        output =
          capture_stdout do
            in_project { run_bootstrap }
          end

        project_path = "/ruby_mono_project"
        package_one_path = "#{project_path}/packages/package_one"
        package_two_path = "#{project_path}/packages/package_two"
        expect(output).to include(
          "Bootstrapping package: package_one (packages/package_one)",
          "Bootstrapping package: package_two (packages/package_two)"
        )
        expect(performed_commands).to eql([
          [package_one_path, "bundle install"],
          [package_two_path, "bundle install"]
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
          it "bootstraps the project" do
            prepare_project :nodejs_npm_single
            output =
              capture_stdout do
                in_project { run_bootstrap }
              end

            expect(output).to include("Bootstrapping package: nodejs_npm_single_project (.)")
            expect(performed_commands).to eql([
              ["/nodejs_npm_single_project", "npm install"],
              ["/nodejs_npm_single_project", "npm link"]
            ])
            expect(exit_status).to eql(0), output
          end

          context "with --ci option" do
            it "calls npm ci" do
              prepare_project :nodejs_npm_single
              output =
                capture_stdout do
                  in_project { run_bootstrap(["--ci"]) }
                end

              expect(output).to include("Bootstrapping package: nodejs_npm_single_project (.)")
              expect(performed_commands).to eql([
                ["/nodejs_npm_single_project", "npm ci"],
                ["/nodejs_npm_single_project", "npm link"]
              ])
              expect(exit_status).to eql(0), output
            end
          end
        end

        context "with mono repo" do
          it "bootstraps the project workspace" do
            prepare_project :nodejs_npm_mono
            output =
              capture_stdout do
                in_project { run_bootstrap }
              end

            project_path = "/nodejs_npm_mono_project"
            package_one_path = "#{project_path}/packages/package_one"
            package_two_path = "#{project_path}/packages/package_two"
            expect(output).to include(
              "Bootstrapping package: package_one (packages/package_one)",
              "Bootstrapping package: package_two (packages/package_two)"
            )
            expect(performed_commands).to eql([
              [project_path, "npm install"],
              [package_one_path, "npm link"],
              [package_two_path, "npm link"]
            ])
            expect(exit_status).to eql(0), output
          end

          context "with node_modules dir in workspace" do
            it "bootstraps the project workspace without the node_modules dir" do
              prepare_project :nodejs_npm_mono
              output =
                capture_stdout do
                  in_project do
                    FileUtils.mkdir "packages/node_modules"
                    run_bootstrap
                  end
                end

              project_path = "/nodejs_npm_mono_project"
              package_one_path = "#{project_path}/packages/package_one"
              package_two_path = "#{project_path}/packages/package_two"
              expect(output).to include(
                "Bootstrapping package: package_one (packages/package_one)",
                "Bootstrapping package: package_two (packages/package_two)"
              )
              expect(performed_commands).to eql([
                [project_path, "npm install"],
                [package_one_path, "npm link"],
                [package_two_path, "npm link"]
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
          it "bootstraps the project" do
            prepare_project :nodejs_yarn_single
            output =
              capture_stdout do
                in_project { run_bootstrap }
              end

            expect(output).to include("Bootstrapping package: nodejs_yarn_single_project (.)")
            expect(performed_commands).to eql([
              ["/nodejs_yarn_single_project", "yarn install"],
              ["/nodejs_yarn_single_project", "yarn link"]
            ])
            expect(exit_status).to eql(0), output
          end
        end

        context "with mono repo" do
          it "bootstraps the project workspace" do
            prepare_project :nodejs_yarn_mono
            output =
              capture_stdout do
                in_project { run_bootstrap }
              end

            project_path = "/nodejs_yarn_mono_project"
            package_one_path = "#{project_path}/packages/package_one"
            package_two_path = "#{project_path}/packages/package_two"
            expect(output).to include(
              "Bootstrapping package: package_one (packages/package_one)",
              "Bootstrapping package: package_two (packages/package_two)"
            )
            expect(performed_commands).to eql([
              [project_path, "yarn install"],
              [package_one_path, "yarn link"],
              [package_two_path, "yarn link"]
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
            in_project { run_bootstrap }
          end

        expect(output).to include("UnknownLanguageError: Unknown language configured"), output
        expect(exit_status).to eql(1), output
      end
    end

    context "with mono repo" do
      it "bootstraps the packages" do
        prepare_project :unknown_mono
        output =
          capture_stdout do
            in_project { run_bootstrap }
          end

        expect(output).to include("UnknownLanguageError: Unknown language configured"), output
        expect(exit_status).to eql(1), output
      end
    end
  end

  def run_bootstrap(args = [])
    Mono::Cli::Wrapper.new(["bootstrap"] + args).execute
  end
end
