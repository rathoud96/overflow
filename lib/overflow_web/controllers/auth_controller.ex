defmodule OverflowWeb.AuthController do
  use OverflowWeb, :controller
  alias Overflow.Accounts
  alias Overflow.User

  @token_salt "user auth salt"

  # POST /api/signup
  def signup(conn, params) do
    with email when is_binary(email) <- Map.get(params, "email"),
         username when is_binary(username) <- Map.get(params, "username"),
         password when is_binary(password) <- Map.get(params, "password") do
      case Accounts.register_user(%{
             "email" => email,
             "username" => username,
             "password" => password
           }) do
        {:ok, %User{} = user} ->
          conn
          |> put_status(:created)
          |> json(%{id: user.id, email: user.email, username: user.username})

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{errors: changeset_errors(changeset)})
      end
    else
      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: %{detail: "Missing required fields: email, username, password"}})
    end
  end

  # POST /api/login
  def login(conn, %{"identifier" => identifier, "password" => password}) do
    case Accounts.authenticate_user(identifier, password) do
      {:ok, %User{} = user} ->
        token = Phoenix.Token.sign(OverflowWeb.Endpoint, @token_salt, user.id)

        conn
        |> put_status(:ok)
        |> json(%{token: token, user: %{id: user.id, email: user.email, username: user.username}})

      :error ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid credentials"})
    end
  end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
