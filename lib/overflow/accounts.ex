defmodule Overflow.Accounts do
  @moduledoc """
  The Accounts context.

  Handles user registration, authentication, and user management functionality.
  """

  import Ecto.Query

  alias Overflow.Accounts.User
  alias Overflow.Repo

  @doc """
  Registers a new user with the given attributes.

  ## Parameters
    * `attrs` - Map containing user registration data including email, username, and password

  ## Returns
    * `{:ok, user}` on successful registration
    * `{:error, changeset}` on validation errors
  """
  @spec register_user(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def register_user(attrs) do
    password = Map.get(attrs, "password")

    if !is_binary(password) or password == "" do
      %User{}
      |> User.changeset(%{
        "email" => attrs["email"],
        "username" => attrs["username"],
        "password_hash" => nil
      })
      |> Ecto.Changeset.add_error(:password, "can't be blank")
      |> then(&{:error, &1})
    else
      %User{}
      |> User.changeset(%{
        email: attrs["email"],
        username: attrs["username"],
        password_hash: Bcrypt.hash_pwd_salt(password)
      })
      |> Repo.insert()
    end
  end

  @doc """
  Authenticates a user with email/username and password.

  ## Parameters
    * `identifier` - User's email or username
    * `password` - User's password

  ## Returns
    * `{:ok, user}` on successful authentication
    * `:error` on authentication failure
  """
  @spec authenticate_user(String.t(), String.t()) :: {:ok, User.t()} | :error
  def authenticate_user(identifier, password) do
    user = Repo.one(from u in User, where: u.email == ^identifier or u.username == ^identifier)

    if user && Bcrypt.verify_pass(password, user.password_hash) do
      {:ok, user}
    else
      :error
    end
  end

  @doc """
  Gets a user by ID, raising if not found.

  ## Parameters
    * `id` - User ID

  ## Returns
    * `User.t()` - The user struct

  ## Raises
    * `Ecto.NoResultsError` if user not found
  """
  @spec get_user!(binary()) :: User.t()
  def get_user!(id), do: Repo.get!(User, id)
end
