defmodule OverflowWeb.ErrorJSON do
  @moduledoc """
  This module is invoked by your endpoint in case of errors on JSON requests.

  Provides standardized error response formatting for all JSON API endpoints.
  See config/config.exs for configuration details.
  """

  # If you want to customize a particular status code,
  # you may add your own clauses, such as:
  #
  # def render("500.json", _assigns) do
  #   %{errors: %{detail: "Internal Server Error"}}
  # end

  @doc """
  Renders error responses in JSON format.

  By default, Phoenix returns the status message from the template name.
  For example, "404.json" becomes "Not Found".

  ## Parameters
    * `template` - The error template name (e.g., "404.json", "500.json")
    * `assigns` - Template assigns (not used in default implementation)

  ## Returns
    * Map with standardized error structure containing detail message

  ## Examples
      render("404.json", %{}) 
      # => %{errors: %{detail: "Not Found"}}

      render("500.json", %{})
      # => %{errors: %{detail: "Internal Server Error"}}
  """
  @spec render(String.t(), map()) :: map()
  def render(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end
end
