defmodule Overflow.Accounts do
  alias Overflow.{Repo, User}
  import Ecto.Query

  # Register a new user
  def register_user(attrs) do
    password = Map.get(attrs, "password")

    cond do
      !is_binary(password) or password == "" ->
        %User{}
        |> User.changeset(%{
          "email" => attrs["email"],
          "username" => attrs["username"],
          "password_hash" => nil
        })
        |> Ecto.Changeset.add_error(:password, "can't be blank")
        |> then(&{:error, &1})

      true ->
        %User{}
        |> User.changeset(%{
          email: attrs["email"],
          username: attrs["username"],
          password_hash: Bcrypt.hash_pwd_salt(password)
        })
        |> Repo.insert()
    end
  end

  # Authenticate a user by email/username and password
  def authenticate_user(identifier, password) do
    user = Repo.one(from u in User, where: u.email == ^identifier or u.username == ^identifier)

    cond do
      user && Bcrypt.verify_pass(password, user.password_hash) ->
        {:ok, user}

      true ->
        :error
    end
  end

  # Fetch a user by id
  def get_user!(id), do: Repo.get!(User, id)
end
