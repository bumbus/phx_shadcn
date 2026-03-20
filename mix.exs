defmodule PhxShadcn.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/bumbus/phx_shadcn"

  def project do
    [
      app: :phx_shadcn,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "PhxShadcn",
      description: "Phoenix LiveView component library mirroring shadcn/ui",
      package: package(),
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:phoenix_live_view, "~> 1.0"},
      {:tailwind_merge, "~> 0.1.0"},
      {:igniter, "~> 0.5", optional: true},
      {:jason, "~> 1.0"}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib priv/static priv/templates package.json .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end
end
