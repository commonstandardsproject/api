defmodule CspApiWeb.ErrorJSON do
  @moduledoc "Default JSON error rendering."

  def render(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end
end
