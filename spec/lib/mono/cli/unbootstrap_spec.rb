# frozen_string_literal: true

RSpec.describe Mono::Cli::Unbootstrap do
  context "with custom command" do
    context "with single package" do
      it "runs custom command" do
        prepare_project :elixir_single
        output =
          capture_stdout do
            in_project do
              configure_command("unbootstrap", "echo unbootstrap")
              run_unbootstrap
            end
          end

        expect(output).to include("Unbootstrapping package: elixir_single_project (.)")
        expect(performed_commands).to eql([
          ["/elixir_single_project", "echo unbootstrap"]
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
              configure_command("unbootstrap", "echo unbootstrap")
              run_unbootstrap
            end
          end

        project_path = "/elixir_mono_project"
        package_one_path = "#{project_path}/packages/package_one"
        package_two_path = "#{project_path}/packages/package_two"
        expect(output).to include("Unbootstrapping package: package_one (packages/package_one)")
        expect(output).to include("Unbootstrapping package: package_two (packages/package_two)")
        expect(performed_commands).to eql([
          [package_one_path, "echo unbootstrap"],
          [package_two_path, "echo unbootstrap"]
        ])
        expect(exit_status).to eql(0), output
      end
    end
  end

  context "with Elixir project" do
    context "with single repo" do
      it "unbootstraps the project" do
        prepare_project :elixir_single
        output =
          capture_stdout do
            in_project { run_unbootstrap }
          end

        expect(output).to include("Unbootstrapping package: elixir_single_project (.)")
        expect(performed_commands).to eql([
          ["/elixir_single_project", "mix deps.clean --all && mix clean"]
        ])
        expect(exit_status).to eql(0), output
      end

      context "with hooks" do
        it "runs hooks around command" do
          prepare_project :elixir_single
          output =
            capture_stdout do
              in_project do
                add_hook("unbootstrap", "pre", "echo before")
                add_hook("unbootstrap", "post", "echo after")
                run_unbootstrap
              end
            end

          expect(output).to include("Unbootstrapping package: elixir_single_project (.)")
          expect(performed_commands).to eql([
            ["/elixir_single_project", "echo before"],
            ["/elixir_single_project", "mix deps.clean --all && mix clean"],
            ["/elixir_single_project", "echo after"]
          ])
          expect(exit_status).to eql(0), output
        end
      end
    end

    context "with mono repo" do
      it "unbootstraps the packages" do
        prepare_project :elixir_mono
        output =
          capture_stdout do
            in_project { run_unbootstrap }
          end

        expect(output).to include("Unbootstrapping package: package_one (packages/package_one)")
        expect(output).to include("Unbootstrapping package: package_two (packages/package_two)")
        expect(performed_commands).to eql([
          ["/elixir_mono_project/packages/package_one", "mix deps.clean --all && mix clean"],
          ["/elixir_mono_project/packages/package_two", "mix deps.clean --all && mix clean"]
        ])
        expect(exit_status).to eql(0), output
      end

      context "with hooks" do
        it "runs hooks around command" do
          prepare_project :elixir_mono
          output =
            capture_stdout do
              in_project do
                add_hook("unbootstrap", "pre", "echo before")
                add_hook("unbootstrap", "post", "echo after")
                run_unbootstrap
              end
            end

          project_path = "/elixir_mono_project"
          package_one_path = "#{project_path}/packages/package_one"
          package_two_path = "#{project_path}/packages/package_two"
          expect(output).to include(
            "Unbootstrapping package: package_one (packages/package_one)",
            "Unbootstrapping package: package_two (packages/package_two)"
          )
          expect(performed_commands).to eql([
            [project_path, "echo before"],
            [package_one_path, "mix deps.clean --all && mix clean"],
            [package_two_path, "mix deps.clean --all && mix clean"],
            [project_path, "echo after"]
          ])
          expect(exit_status).to eql(0), output
        end
      end
    end
  end

  context "with Ruby project" do
    context "with single repo" do
      it "unbootstraps the project" do
        prepare_project :ruby_single
        output =
          capture_stdout do
            in_project { run_unbootstrap }
          end

        expect(output).to include("Unbootstrapping package: ruby_single_project (.)")
        expect(performed_commands).to eql([
          ["/ruby_single_project", "rm -rf vendor/ tmp/"]
        ])
        expect(exit_status).to eql(0), output
      end
    end

    context "with mono repo" do
      it "unbootstraps the packages" do
        prepare_project :ruby_mono
        output =
          capture_stdout do
            in_project { run_unbootstrap }
          end

        expect(output).to include("Unbootstrapping package: package_one (packages/package_one)")
        expect(output).to include("Unbootstrapping package: package_two (packages/package_two)")
        expect(performed_commands).to eql([
          ["/ruby_mono_project/packages/package_one", "rm -rf vendor/ tmp/"],
          ["/ruby_mono_project/packages/package_two", "rm -rf vendor/ tmp/"]
        ])
        expect(exit_status).to eql(0), output
      end
    end
  end

  context "with Node.js project" do
    context "with npm" do
      context "with single repo" do
        it "unbootstraps the project" do
          prepare_project :nodejs_npm_single
          output =
            capture_stdout do
              in_project { run_unbootstrap }
            end

          expect(output).to include("Unbootstrapping package: nodejs_npm_single_project (.)")
          expect(performed_commands).to eql([
            ["/nodejs_npm_single_project", "rm -rf node_modules"],
            ["/nodejs_npm_single_project", "rm -rf node_modules"]
          ])
          expect(exit_status).to eql(0), output
        end
      end

      context "with mono repo" do
        it "unbootstraps the project workspace" do
          prepare_project :nodejs_npm_mono
          output =
            capture_stdout do
              in_project { run_unbootstrap }
            end

          project_path = "/nodejs_npm_mono_project"
          package_one_path = "#{project_path}/packages/package_one"
          package_two_path = "#{project_path}/packages/package_two"
          expect(output).to include(
            "Unbootstrapping package: package_one (packages/package_one)",
            "Unbootstrapping package: package_two (packages/package_two)"
          )
          expect(performed_commands).to eql([
            [project_path, "rm -rf node_modules"],
            [project_path, "rm -rf packages/node_modules"],
            [package_one_path, "rm -rf node_modules"],
            [package_two_path, "rm -rf node_modules"]
          ])
          expect(exit_status).to eql(0), output
        end
      end
    end

    context "with yarn" do
      context "with single repo" do
        it "unbootstraps the project" do
          prepare_project :nodejs_yarn_single
          output =
            capture_stdout do
              in_project { run_unbootstrap }
            end

          expect(output).to include("Unbootstrapping package: nodejs_yarn_single_project (.)")
          expect(performed_commands).to eql([
            ["/nodejs_yarn_single_project", "rm -rf node_modules"],
            ["/nodejs_yarn_single_project", "rm -rf node_modules"]
          ])
          expect(exit_status).to eql(0), output
        end
      end

      context "with mono repo" do
        it "unbootstraps the project workspace" do
          prepare_project :nodejs_yarn_mono
          output =
            capture_stdout do
              in_project { run_unbootstrap }
            end

          project_path = "/nodejs_yarn_mono_project"
          package_one_path = "#{project_path}/packages/package_one"
          package_two_path = "#{project_path}/packages/package_two"
          expect(output).to include(
            "Unbootstrapping package: package_one (packages/package_one)",
            "Unbootstrapping package: package_two (packages/package_two)"
          )
          expect(performed_commands).to eql([
            [project_path, "rm -rf node_modules"],
            [project_path, "rm -rf packages/node_modules"],
            [package_one_path, "rm -rf node_modules"],
            [package_two_path, "rm -rf node_modules"]
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
            in_project { run_unbootstrap }
          end

        expect(output).to include("UnknownLanguageError: Unknown language configured"), output
        expect(exit_status).to eql(1), output
      end
    end

    context "with mono repo" do
      it "unbootstraps the packages" do
        prepare_project :unknown_mono
        output =
          capture_stdout do
            in_project { run_unbootstrap }
          end

        expect(output).to include("UnknownLanguageError: Unknown language configured"), output
        expect(exit_status).to eql(1), output
      end
    end
  end

  def run_unbootstrap(args = [])
    Mono::Cli::Wrapper.new(["unbootstrap"] + args).execute
  end
end
