# frozen_string_literal: true

RSpec.describe Mono::Cli::Bootstrap do
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
    end

    context "with mono repo" do
      it "bootstraps the packages" do
        prepare_project :elixir_mono
        output =
          capture_stdout do
            in_project { run_bootstrap }
          end

        expect(output).to include("Bootstrapping package: package_one (packages/package_one)")
        expect(output).to include("Bootstrapping package: package_two (packages/package_two)")
        expect(performed_commands).to eql([
          ["/elixir_mono_project/packages/package_one", "mix deps.get"],
          ["/elixir_mono_project/packages/package_two", "mix deps.get"]
        ])
        expect(exit_status).to eql(0), output
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

        expect(output).to include("Bootstrapping package: package_one (packages/package_one)")
        expect(output).to include("Bootstrapping package: package_two (packages/package_two)")
        expect(performed_commands).to eql([
          ["/ruby_mono_project/packages/package_one", "bundle install"],
          ["/ruby_mono_project/packages/package_two", "bundle install"]
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

            expect(output).to include("Bootstrapping project")
            expect(performed_commands).to eql([
              ["/nodejs_npm_single_project", "npm install"],
              ["/nodejs_npm_single_project", "npm link"]
            ])
            expect(exit_status).to eql(0), output
          end
        end

        context "with mono repo" do
          it "bootstraps the project workspace" do
            prepare_project :nodejs_npm_mono
            output =
              capture_stdout do
                in_project { run_bootstrap }
              end

            expect(output).to include("Bootstrapping project")
            expect(performed_commands).to eql([
              ["/nodejs_npm_mono_project", "npm install"],
              ["/nodejs_npm_mono_project/packages/package_one", "npm link"],
              ["/nodejs_npm_mono_project/packages/package_two", "npm link"]
            ])
            expect(exit_status).to eql(0), output
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

            expect(output).to include("Bootstrapping project")
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

            expect(output).to include("Bootstrapping project")
            expect(performed_commands).to eql([
              ["/nodejs_yarn_mono_project", "yarn install"],
              ["/nodejs_yarn_mono_project/packages/package_one", "yarn link"],
              ["/nodejs_yarn_mono_project/packages/package_two", "yarn link"]
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
    Mono::Cli::Wrapper.new(:bootstrap, args).execute
  end
end
