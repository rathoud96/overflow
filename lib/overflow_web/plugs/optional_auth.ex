defmodule OverflowWeb.Plugs.OptionalAuth do
  @moduledoc """
  Plug to optionally authenticate users via token.
  Sets current_user if valid token is provided, but doesn't halt if not.
  """

  import Plug.Conn

  alias Overflow.Accounts.User
  alias Overflow.Repo

  @token_salt Application.compile_env(:overflow, :token_salt, "user auth salt")
  # 24 hours in seconds
  @token_max_age 86_400

  def init(opts), do: opts

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, user_id} <-
           Phoenix.Token.verify(OverflowWeb.Endpoint, @token_salt, token, max_age: @token_max_age),
         %User{} = user <- Repo.get(User, user_id) do
      assign(conn, :current_user, user)
    else
      _ ->
        conn
    end
  end
end
