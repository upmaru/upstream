defmodule Blazay.Mixfile do
  @moduledoc """
  Mixfile for project.
  """
  use Mix.Project

  def project do
    [
      app: :blazay,
      version: "1.0.2",
      elixir: "~> 1.5",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      source_url: "https://github.com/artellectual/blazay",
      name: "Blazay",
      description: description(),
      deps: deps(),
      package: package(),
      dialyzer: [
        plt_add_deps: true,
      ]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [
      mod: {Blazay, []},
      extra_applications: [
        :cowboy,
        :plug,
        :httpoison,
        :poison,
        :logger
      ]
    ]
  end

  defp description do
    """
    Blazay is for integrating into projects that need to do large 
    file uploads to B2 service. It integrates tightly with Backblaze B2.
    """
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:httpoison, "~> 0.11.0"},
      {:cowboy, "~> 1.0"},
      {:plug, "~> 1.0"},
      {:poison, "~> 3.0"},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:exvcr, "~> 0.8", only: :test},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      name: :blazay,
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Zack Siri"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/artellectual/blazay"}
    ]
  end
end
