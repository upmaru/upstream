defmodule Upstream.Mixfile do
  @moduledoc """
  Mixfile for project.
  """
  use Mix.Project

  def project do
    [
      app: :upstream,
      version: "2.0.4",
      elixir: "~> 1.6",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      source_url: "https://gitlab.com/upmaru/upstream",
      name: "Upstream",
      description: description(),
      deps: deps(),
      package: package(),
      dialyzer: [
        plt_add_deps: :transitive
      ],
      preferred_cli_env: [
        vcr: :test,
        "vcr.delete": :test,
        "vcr.check": :test,
        "vcr.show": :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [
      extra_applications: [
        :plug,
        :httpoison,
        :logger
      ],
      mod: {Upstream.Application, []}
    ]
  end

  defp description do
    """
    Upstream is for integrating into projects that need to do large
    file uploads to B2 service. It integrates tightly with Backblaze B2 for now,
    with plans to support Amazon S3.
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
      {:httpoison, "~> 1.0.0"},
      {:plug, "~> 1.0"},
      {:jason, "~> 1.1"},

      # Env specific
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:exvcr, "~> 0.10", only: :test, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.8", only: :test},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      name: :upstream,
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Zack Siri"],
      licenses: ["MIT"],
      links: %{"GitLab" => "https://gitlab.com/upmaru/upstream"}
    ]
  end
end
