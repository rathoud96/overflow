defmodule Overflow.Search.Question do
  @moduledoc """
  Schema for tracking user search questions.

  This schema stores the search queries that users have made,
  allowing for search history tracking and analytics.
  """

  use Ecto.Schema
  use TypedEctoSchema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "search_questions" do
    field :question, :string
    belongs_to :user, Overflow.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(search_question, attrs) do
    search_question
    |> cast(attrs, [:question, :user_id])
    |> validate_required([:question, :user_id])
    |> validate_length(:question, min: 1, max: 1000)
    |> foreign_key_constraint(:user_id)
  end
end
