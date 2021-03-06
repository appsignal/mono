# frozen_string_literal: true

RSpec.describe Mono::Cli::Custom do
  context "with single repo" do
    it "runs command in root" do
      prepare_project :elixir_single
      output =
        capture_stdout do
          in_project { run_custom ["echo", "123"] }
        end

      expect(output).to include("Custom command for package: elixir_single_project (.)")
      expect(performed_commands).to eql([
        ["/elixir_single_project", "echo 123"]
      ])
      expect(exit_status).to eql(0), output
    end

    context "with hooks" do
      it "runs hooks around command" do
        prepare_project :elixir_single
        output =
          capture_stdout do
            in_project do
              add_hook("custom", "pre", "echo before")
              add_hook("custom", "post", "echo after")
              run_custom ["echo", "123"]
            end
          end

        expect(output).to include("Custom command for package: elixir_single_project (.)")
        expect(performed_commands).to eql([
          ["/elixir_single_project", "echo before"],
          ["/elixir_single_project", "echo 123"],
          ["/elixir_single_project", "echo after"]
        ])
        expect(exit_status).to eql(0), output
      end
    end
  end

  context "with mono repo" do
    it "runs command in each package" do
      prepare_project :elixir_mono
      output =
        capture_stdout do
          in_project { run_custom ["echo", "123"] }
        end

      package_one_path = "/elixir_mono_project/packages/package_one"
      package_two_path = "/elixir_mono_project/packages/package_two"
      expect(output).to include(
        "Custom command for package: package_one (packages/package_one)",
        "Custom command for package: package_two (packages/package_two)"
      )
      expect(performed_commands).to eql([
        [package_one_path, "echo 123"],
        [package_two_path, "echo 123"]
      ])
      expect(exit_status).to eql(0), output
    end

    context "with hooks" do
      it "runs hooks around command" do
        prepare_project :elixir_mono
        output =
          capture_stdout do
            in_project do
              add_hook("custom", "pre", "echo before")
              add_hook("custom", "post", "echo after")
              run_custom ["echo", "123"]
            end
          end

        project_path = "/elixir_mono_project"
        package_one_path = "#{project_path}/packages/package_one"
        package_two_path = "#{project_path}/packages/package_two"
        expect(output).to include(
          "Custom command for package: package_one (packages/package_one)",
          "Custom command for package: package_two (packages/package_two)"
        )
        expect(performed_commands).to eql([
          [project_path, "echo before"],
          [package_one_path, "echo 123"],
          [package_two_path, "echo 123"],
          [project_path, "echo after"]
        ])
        expect(exit_status).to eql(0), output
      end
    end

    context "with only one package selected" do
      it "only tests the selected package" do
        prepare_project :elixir_mono
        output =
          capture_stdout do
            in_project do
              run_custom(["echo 123", "--package", "package_one"])
            end
          end

        project_path = "/elixir_mono_project"
        package_one_path = "#{project_path}/packages/package_one"
        expect(output).to include(
          "Custom command for package: package_one (packages/package_one)"
        ), output
        expect(output).to_not include(
          "Custom command for package: package_two (packages/package_two)"
        ), output
        expect(performed_commands).to eql([
          [package_one_path, "echo 123"]
        ])
        expect(exit_status).to eql(0), output
      end
    end

    context "with multiple packages selected" do
      it "builds the selected packages" do
        prepare_project :elixir_mono
        output =
          capture_stdout do
            in_project do
              run_custom(["echo 123", "--package", "package_one,package_two"])
            end
          end

        project_path = "/elixir_mono_project"
        package_one_path = "#{project_path}/packages/package_one"
        package_two_path = "#{project_path}/packages/package_two"
        expect(output).to include(
          "Custom command for package: package_one (packages/package_one)",
          "Custom command for package: package_two (packages/package_two)"
        ), output
        expect(performed_commands).to eql([
          [package_one_path, "echo 123"],
          [package_two_path, "echo 123"]
        ])
        expect(exit_status).to eql(0), output
      end
    end

    context "with --parallel" do
      it "runs the command in parallel" do
        prepare_project :elixir_mono
        output =
          capture_stdout do
            in_project do
              perform_commands do
                run_custom(["echo 123", "--parallel"])
              end
            end
          end

        project_path = "/elixir_mono_project"
        package_one_path = "#{project_path}/packages/package_one"
        package_two_path = "#{project_path}/packages/package_two"
        expect(output).to include(
          "Custom command for project in parallel",
          "Custom command for package: package_one (packages/package_one)",
          "Custom command for package: package_two (packages/package_two)"
        ), output
        expect(performed_commands.sort_by { |path, _| path }).to eql([
          [package_one_path, "echo 123"],
          [package_two_path, "echo 123"]
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
              run_custom(["--package", "package_one,package_three"])
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

  def run_custom(args = [])
    Mono::Cli::Wrapper.new(["run"] + args).execute
  end
end
