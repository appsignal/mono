# frozen_string_literal: true

RSpec.describe Mono::Cli::Bootstrap do
  context "with Elixir project" do
    context "with single repo" do
      it "bootstraps the project" do
        output =
          capture_stdout do
            in_elixir_single_project { described_class.new([]).execute }
          end

        expect(performed_commands).to eql([
          ["/elixir_single_project", "mix deps.get"]
        ])
        expect(output).to include("Bootstrapping package: elixir_single_project (.)")
      end
    end

    context "with mono repo" do
      it "bootstraps the packages" do
        output =
          capture_stdout do
            in_elixir_mono_project { described_class.new([]).execute }
          end

        expect(performed_commands).to eql([
          ["/elixir_mono_project/packages/package_two", "mix deps.get"],
          ["/elixir_mono_project/packages/package_one", "mix deps.get"]
        ])
        expect(output).to include("Bootstrapping package: package_two (packages/package_two)")
        expect(output).to include("Bootstrapping package: package_one (packages/package_one)")
      end
    end
  end

  context "with Ruby project" do
    context "with single repo" do
      it "bootstraps the project" do
        output =
          capture_stdout do
            in_ruby_single_project { described_class.new([]).execute }
          end

        expect(performed_commands).to eql([
          ["/ruby_single_project", "bundle install"]
        ])
        expect(output).to include("Bootstrapping package: ruby_single_project (.)")
      end
    end

    context "with mono repo" do
      it "bootstraps the packages" do
        output =
          capture_stdout do
            in_ruby_mono_project { described_class.new([]).execute }
          end

        expect(performed_commands).to eql([
          ["/ruby_mono_project/packages/package_two", "bundle install"],
          ["/ruby_mono_project/packages/package_one", "bundle install"]
        ])
        expect(output).to include("Bootstrapping package: package_two (packages/package_two)")
        expect(output).to include("Bootstrapping package: package_one (packages/package_one)")
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
            output =
              capture_stdout do
                in_nodejs_single_project { described_class.new([]).execute }
              end

            expect(performed_commands).to eql([
              ["/nodejs_npm_single_project", "npm install"]
            ])
            expect(output).to include("Bootstrapping project")
          end
        end

        context "with mono repo" do
          it "bootstraps the project workspace" do
            output =
              capture_stdout do
                in_nodejs_mono_project { described_class.new([]).execute }
              end

            expect(performed_commands).to eql([
              ["/nodejs_npm_mono_project", "npm install"]
            ])
            expect(output).to include("Bootstrapping project")
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
            output =
              capture_stdout do
                in_nodejs_single_project(:yarn) { described_class.new([]).execute }
              end

            expect(performed_commands).to eql([
              ["/nodejs_yarn_single_project", "yarn install"]
            ])
            expect(output).to include("Bootstrapping project")
          end
        end

        context "with mono repo" do
          it "bootstraps the project workspace" do
            output =
              capture_stdout do
                in_nodejs_mono_project(:yarn) { described_class.new([]).execute }
              end

            expect(performed_commands).to eql([
              ["/nodejs_yarn_mono_project", "yarn install"]
            ])
            expect(output).to include("Bootstrapping project")
          end
        end
      end
    end
  end
end
