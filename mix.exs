defmodule RavixEcto.MixProject do
  use Mix.Project

  def project do
    [
      app: :ravix_ecto,
      version: "0.3.7",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ],
      source_url: "https://github.com/YgorCastor/ravix-ecto",
      homepage_url: "https://github.com/YgorCastor/ravix-ecto",
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ecto, "~> 3.7"},
      {:ravix, "~> 0.6"},
      {:ok, "~> 2.3"},
      {:gradient, github: "esl/gradient", only: [:dev, :test], runtime: false},
      {:elixir_sense, github: "elixir-lsp/elixir_sense", only: [:dev]},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:ex_machina, "~> 2.7", only: :test},
      {:assertions, "~> 0.19", only: :test},
      {:excoveralls, "~> 0.14", only: :test},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:version_tasks, "~> 0.12", only: [:dev, :test], runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp description() do
    "An Ecto wrapper for RavenDB"
  end

  defp package() do
    [
      maintainers: [
        "Ygor Castor"
      ],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/YgorCastor/ravix-ecto"},
      sponsor: "ycastor.eth"
    ]
  end
end
