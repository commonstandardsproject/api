ExUnit.start()

# Refuse to start if the configured Repo points anywhere other than a
# database whose name contains "test". The Ruby rspec suite has the same
# safety belt — `if $db.database.name == "common-standards-project-testing"`.
url = Application.get_env(:csp_api, CspApi.Repo)[:url]

unless is_binary(url) and String.contains?(url, "test") do
  raise """
  Test repo is not pointing at a *test* database.

  Configured Repo URL: #{inspect(url)}

  Set MONGO_URL_TEST or update config/test.exs to a database whose name
  contains the substring "test".
  """
end

# Use the test email adapter so we can assert on what gets sent.
Application.put_env(:csp_api, :email_adapter, CspApi.Email.TestAdapter)

# Drop the test database once at boot so we start from a clean slate.
# When MongoDB isn't reachable (CI / pure-unit runs) we tag any test that
# depends on the Repo as `:mongo` and skip it. Tests that don't touch
# Mongo still run.
try do
  case Mongo.Ecto.command(CspApi.Repo, dropDatabase: 1) do
    {:ok, _} ->
      :ok

    {:error, reason} ->
      IO.warn("Could not reset Mongo test database: #{inspect(reason)} — excluding :mongo tagged tests")
      ExUnit.configure(exclude: [:mongo])
  end
rescue
  e ->
    IO.warn("Could not reach MongoDB: #{Exception.message(e)} — excluding :mongo tagged tests")
    ExUnit.configure(exclude: [:mongo])
catch
  :exit, reason ->
    IO.warn("MongoDB exit while resetting db: #{inspect(reason)} — excluding :mongo tagged tests")
    ExUnit.configure(exclude: [:mongo])
end
