defmodule CspApiWeb.Router do
  use CspApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  # The Ruby app applies `Api-Key` auth to every request except swagger_doc
  # and the sitemap. The Phoenix port matches that.
  pipeline :api_key do
    plug CspApiWeb.Plugs.ApiKeyAuth
  end

  # The Ruby app additionally requires a valid JWT for any mutating
  # operation; in test mode an `Authorization: TEST` header bypasses the
  # JWT decode. Read-only endpoints don't run through this.
  pipeline :jwt do
    plug CspApiWeb.Plugs.JwtAuth
  end

  scope "/api/v1", CspApiWeb do
    pipe_through [:api, :api_key]

    get "/jurisdictions", JurisdictionsController, :index
    get "/jurisdictions/:id", JurisdictionsController, :show

    get "/standard_sets/:id", StandardSetsController, :show
    get "/standard_documents/:id", StandardDocumentsController, :show

    get "/pull_requests", PullRequestsController, :index
    get "/pull_requests/user/:user_id", PullRequestsController, :for_user
    get "/pull_requests/:id", PullRequestsController, :show
  end

  scope "/api/v1", CspApiWeb do
    pipe_through [:api, :api_key, :jwt]

    post "/users/signed_in", UsersController, :signed_in
    get "/users/:email", UsersController, :show
    post "/users/:id/allowed_origins", UsersController, :set_allowed_origins

    post "/jurisdictions", JurisdictionsController, :create

    post "/pull_requests", PullRequestsController, :create
    post "/pull_requests/:id", PullRequestsController, :user_update
    post "/pull_requests/:id/submit", PullRequestsController, :submit
    post "/pull_requests/:id/change_status", PullRequestsController, :change_status
    post "/pull_requests/:id/comment", PullRequestsController, :comment
  end

  # Public — no API key required, like the Ruby app's swagger_doc and
  # sitemap.
  scope "/api/v1", CspApiWeb do
    pipe_through [:api]
    get "/swagger_doc", SwaggerController, :index
    get "/sitemap.xml", SitemapController, :show
  end

  # Liveness + Mongo reachability — for load balancers / uptime checks.
  # Outside any API-version prefix so monitoring URLs stay stable across
  # future API revisions.
  scope "/", CspApiWeb do
    pipe_through [:api]
    get "/healthz", HealthController, :show
  end
end
