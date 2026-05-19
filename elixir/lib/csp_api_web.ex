defmodule CspApiWeb do
  @moduledoc """
  Shared boilerplate for controllers and JSON views. The Ruby app used
  Grape entities; here we use plain modules that take a struct/map and
  return a JSON-encodable map.
  """

  def controller do
    quote do
      use Phoenix.Controller, formats: [:json]
      import Plug.Conn
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  defmacro __using__(which) when is_atom(which), do: apply(__MODULE__, which, [])
end
