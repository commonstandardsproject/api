defmodule CspApi.MixProject do
  use Mix.Project

  def project do
    [
      app: :csp_api,
      version: "0.1.0",
      elixir: "~> 1.19",
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
      # Vendored copy of mongodb_ecto 2.1.1 with a patch to scope the
      # primary-key → _id rename to the top-level document (the upstream
      # adapter rewrites nested `:id` keys inside `embeds_one` docs too,
      # which breaks wire-format parity with the Ruby app's
      # `jurisdiction.id`-style filters). The patch is in
      # vendor_deps/mongodb_ecto.patch — submit upstream.
      {:mongodb_ecto, path: "vendor_deps/mongodb_ecto"},

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
