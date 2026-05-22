defmodule CspApi.MixProject do
  use Mix.Project

  def project do
    [
      app: :csp_api,
      version: "0.1.0",
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      releases: releases(),
      aliases: aliases(),
      deps: deps()
    ]
  end

  defp releases do
    [
      csp_api: [
        include_executables_for: [:unix],
        applications: [csp_api: :permanent]
      ]
    ]
  end

  def application do
    [
      mod: {CspApi.Application, []},
      extra_applications: [:logger, :runtime_tools, :xmerl]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.7.18"},
      {:phoenix_pubsub, "~> 2.1"},
      {:bandit, "~> 1.5"},
      {:jason, "~> 1.4"},

      # Ecto + the official MongoDB adapter
      {:ecto, "~> 3.10"},
      # Tracks elixir-mongo/mongodb_ecto#scope-pk-rename-to-top-level —
      # scopes the primary-key → _id rename to the outermost document so
      # `embeds_one` sub-docs keep their own `:id` field (matching the
      # wire format the Ruby app reads/writes). Swap back to a Hex
      # release once that branch is merged and tagged.
      {:mongodb_ecto, github: "elixir-mongo/mongodb_ecto", branch: "scope-pk-rename-to-top-level"},

      {:joken, "~> 2.6"},
      {:elixir_uuid, "~> 1.2"},
      # Hex package is `algolia_ex` (slab fork), but the actual OTP app
      # is named `:algolia` — use the `hex:` override to bridge.
      {:algolia, "~> 0.11", hex: :algolia_ex},
      {:corsica, "~> 2.1"},
      {:open_api_spex, "~> 3.22"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      test: ["test"]
    ]
  end
end
