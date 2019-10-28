defmodule ITKHealthCheckex.MixProject do
  use Mix.Project

  @project_url "https://github.com/inside-track/itk_health_checkex"
  @version "0.0.1"

  def project do
    [
      app: :itk_health_checkex,
      version: @version,
      elixir: "~> 1.8",
      description: description(),
      source_url: @project_url,
      homepage_url: @project_url,
      start_permanent: Mix.env() == :prod,
      package: package(),
      docs: [main: "readme", extras: ["README.md"]],
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:mix],
        plt_add_deps: true
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.0"},
      {:jason, "~> 1.0"},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:credo, git: "https://github.com/rrrene/credo.git", only: [:dev, :test]},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false}
    ]
  end

  defp description, do: "Plug based health check provided as macros."

  defp package do
    [
      maintainers: ["Ramy Tamer", "Islam Hamdi"],
      organization: "inside-track",
      files: ~w(lib config test .formatter.exs mix.exs README*),
      licenses: ["MIT"],
      links: %{
        "GitHub" => @project_url
      }
    ]
  end
end
