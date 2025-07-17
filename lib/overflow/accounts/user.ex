defmodule Overflow.Accounts.User do
  @moduledoc """
  User schema representing a user account in the system.

  Users can search for questions and their search history is tracked
  through the SearchQuestion association.
  """

  use Ecto.Schema
  use TypedEctoSchema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "users" do
    field :email, :string
    field :username, :string
    field :password_hash, :string

    has_many :search_questions, Overflow.Search.Question

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :username, :password_hash])
    |> validate_required([:email, :username, :password_hash])
    |> validate_format(:email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/,
      message: "must be a valid email address"
    )
    |> validate_length(:username, min: 3, max: 39)
    |> validate_length(:email, max: 254)
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end
end
