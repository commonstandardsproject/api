defmodule CspApi.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    mongo_opts = Application.fetch_env!(:csp_api, :mongo)

    children = [
      {Phoenix.PubSub, name: CspApi.PubSub},
      {Mongo, mongo_opts},
      CspApiWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: CspApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    CspApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
