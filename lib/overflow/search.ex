defmodule Overflow.Search do
  @moduledoc """
  The Search context.

  Handles search functionality including search question tracking,
  search operations, and integration with external search providers.
  """

  import Ecto.Query, warn: false
  alias Overflow.Repo
  alias Overflow.Search.Question

  @doc """
  Creates a search question for a user.

  ## Examples

      iex> create_search_question(%{question: "How to use Elixir?", user_id: user_id})
      {:ok, %Question{}}

      iex> create_search_question(%{question: "", user_id: user_id})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_search_question(map()) :: {:ok, Question.t()} | {:error, Ecto.Changeset.t()}
  def create_search_question(attrs \\ %{}) do
    %Question{}
    |> Question.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns the last N search questions for a user, ordered by most recent first.

  ## Parameters
    * `user_id` - The user's ID
    * `limit` - Number of questions to return (default: 5)

  ## Examples

      iex> get_recent_questions_for_user(user_id)
      [%Question{}, ...]

  """
  @spec get_recent_questions_for_user(binary(), integer()) :: [Question.t()]
  def get_recent_questions_for_user(user_id, limit \\ 5) do
    # Handle negative limits gracefully by returning empty list
    if limit <= 0 do
      []
    else
      Question
      |> where([sq], sq.user_id == ^user_id)
      |> order_by([sq], desc: sq.inserted_at)
      |> limit(^limit)
      |> Repo.all()
    end
  end

  @doc """
  Gets a single search question.

  Raises `Ecto.NoResultsError` if the Question does not exist.

  ## Examples

      iex> get_search_question!(123)
      %Question{}

      iex> get_search_question!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_search_question!(binary()) :: Question.t()
  def get_search_question!(id), do: Repo.get!(Question, id)

  @doc """
  Performs a search operation using the configured search implementation.

  ## Parameters
    * `query` - The search query string

  ## Returns
    * `{:ok, results}` on successful search
    * `{:error, reason}` on search failure
  """
  @spec search(String.t()) :: {:ok, list()} | {:error, any()}
  def search(query) do
    search_impl = Application.get_env(:overflow, :search_impl, Overflow.Search.Engine)
    search_impl.search(query)
  end
end
