defmodule CspApi.MixProject do
  use Mix.Project

  def project do
    [
      app: :csp_api,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {CspApi.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.7.10"},
      {:phoenix_pubsub, "~> 2.1"},
      {:plug_cowboy, "~> 2.6"},
      {:jason, "~> 1.4"},

      # Ecto + the official MongoDB adapter
      {:ecto, "~> 3.10"},
      {:mongodb_ecto, "~> 1.1"},

      {:joken, "~> 2.6"},
      {:elixir_uuid, "~> 1.2"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      test: ["test"]
    ]
  end
end
