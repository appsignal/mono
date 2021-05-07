# frozen_string_literal: true

RSpec.describe Mono::Cli::Init do
  around do |example|
    with_mock_stdin { example.run }
  end

  context "with single project" do
    it "creates a mono.yml file" do
      prepare_project :empty
      add_cli_input "ruby" # Language
      add_cli_input "" # No package path
      in_project { expect(File.exist?("mono.yml")).to be_falsy }
      output = capture_stdout { in_project { run_init } }

      expect(output).to include(
        "Language (ruby/elixir/nodejs):",
        "Packages directory (leave empty for single package repo):"
      )
      in_project do
        config = YAML.safe_load(File.read("mono.yml"))
        expect(config).to eql("language" => "ruby")
      end
      expect(performed_commands).to eql([])
      expect(exit_status).to eql(0)
    end
  end

  context "with mono project" do
    it "creates a mono.yml file" do
      prepare_project :empty
      add_cli_input "elixir" # Language
      add_cli_input "packages" # Packages path
      in_project { expect(File.exist?("mono.yml")).to be_falsy }
      output = capture_stdout { in_project { run_init } }

      expect(output).to include(
        "Language (ruby/elixir/nodejs):",
        "Packages directory (leave empty for single package repo):"
      )
      in_project do
        config = YAML.safe_load(File.read("mono.yml"))
        expect(config).to eql(
          "language" => "elixir",
          "packages_dir" => "packages",
          "tag_prefix" => ""
        )
      end
      expect(performed_commands).to eql([])
      expect(exit_status).to eql(0)
    end
  end

  context "without a language specified" do
    it "keeps asking for a valid language" do
      prepare_project :empty
      add_cli_input "" # No language at all
      add_cli_input "unknown" # Unknown language
      add_cli_input "nodejs" # Valid language
      add_cli_input "" # No package path
      in_project { expect(File.exist?("mono.yml")).to be_falsy }
      output = capture_stdout { in_project { run_init } }

      expect(output).to include(
        "Language (ruby/elixir/nodejs):",
        "Packages directory (leave empty for single package repo):"
      )
      expect(output.scan(/Language /).length).to eql(3)
      expect(output).to include("Unknown language `unknown`")
      in_project do
        config = YAML.safe_load(File.read("mono.yml"))
        expect(config).to eql("language" => "nodejs")
      end
      expect(performed_commands).to eql([])
      expect(exit_status).to eql(0)
    end
  end

  def run_init(args = [])
    prepare_cli_input
    Mono::Cli::Wrapper.new(["init"] + args).execute
  end
end
