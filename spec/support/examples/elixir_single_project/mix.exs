defmodule Appsignal.Mixfile do
  use Mix.Project

  @source_url "https://github.com/appsignal/elixir_single_project"
  @version "1.2.3"

  def project do
    [
      app: :elixir_single_project,
      version: @version,
      name: "elixir_single_project",
      description: description(),
      package: package(),
      homepage_url: "https://appsignal.com",
      elixir: "~> 1.9",
      docs: [
        main: "readme",
        source_ref: @version,
        source_url: @source_url,
        extras: ["CHANGELOG.md"]
      ],
      deps: [
      ]
    ]
  end

  defp description do
    "Dummy package description"
  end

  defp package do
    %{
      files: [
        "*.md"
      ],
      maintainers: ["Tom de Bruijn"],
      licenses: ["MIT"],
      links: %{
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "GitHub" => @source_url
      }
    }
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Appsignal, []}
    ]
  end
end
