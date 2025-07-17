defmodule OverflowWeb.AuthController do
  @moduledoc """
  Controller for handling user authentication operations including signup and login.
  """

  use OverflowWeb, :controller
  alias Overflow.Accounts
  alias Overflow.Accounts.User

  @token_salt Application.compile_env(:overflow, :token_salt, "user auth salt")
  # 24 hours in seconds
  @token_max_age 86_400

  @doc """
  Registers a new user account and automatically logs them in.

  Creates a new user with the provided email, username, and password.
  Returns user information and authentication token on successful registration.

  ## Parameters
    * `conn` - The Plug.Conn struct
    * `params` - Map containing:
      * `"email"` - User's email address (required)
      * `"username"` - User's username (required)
      * `"password"` - User's password (required)

  ## Returns
    * `201` with user information and token on successful registration
    * `422` with validation errors on failure

  ## Examples
      POST /api/signup
      {
        "email": "user@example.com",
        "username": "username",
        "password": "password123"
      }

      Response (success):
      {
        "token": "jwt_token_string",
        "user": {
          "id": "uuid",
          "email": "user@example.com",
          "username": "username"
        }
      }

      Response (error):
      {
        "errors": {
          "email": ["has already been taken"]
        }
      }
  """
  @spec signup(Plug.Conn.t(), map()) :: Plug.Conn.t()
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
          token =
            Phoenix.Token.sign(OverflowWeb.Endpoint, @token_salt, user.id, max_age: @token_max_age)

          conn
          |> put_status(:created)
          |> json(%{
            token: token,
            user: %{id: user.id, email: user.email, username: user.username}
          })

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

  @doc """
  Authenticates a user and returns a JWT token.

  Validates user credentials and returns an authentication token on success.
  The identifier can be either email or username.

  This function has multiple clauses:
  1. With valid identifier and password parameters
  2. Fallback for missing or invalid parameters

  ## Parameters
    * `conn` - The Plug.Conn struct
    * `params` - Map containing:
      * `"identifier"` - User's email or username (required)
      * `"password"` - User's password (required)

  ## Returns
    * `200` with token and user information on successful authentication
    * `401` with error message for invalid credentials
    * `400` with error message for missing parameters

  ## Examples
      POST /api/login
      {
        "identifier": "user@example.com",
        "password": "password123"
      }

      Response (success):
      {
        "token": "jwt_token_string",
        "user": {
          "id": "uuid",
          "email": "user@example.com",
          "username": "username"
        }
      }

      Response (invalid credentials):
      {
        "error": "Invalid credentials"
      }

      Response (missing fields):
      {
        "error": "Missing required fields: identifier, password"
      }
  """
  @spec login(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def login(conn, %{"identifier" => identifier, "password" => password})
      when is_binary(identifier) and is_binary(password) do
    case Accounts.authenticate_user(identifier, password) do
      {:ok, %User{} = user} ->
        token =
          Phoenix.Token.sign(OverflowWeb.Endpoint, @token_salt, user.id, max_age: @token_max_age)

        conn
        |> put_status(:ok)
        |> json(%{token: token, user: %{id: user.id, email: user.email, username: user.username}})

      :error ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid credentials"})
    end
  end

  @spec login(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def login(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required fields: identifier, password"})
  end

  @spec changeset_errors(Ecto.Changeset.t()) :: map()
  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
