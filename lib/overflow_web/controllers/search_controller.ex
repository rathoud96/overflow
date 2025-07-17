defmodule OverflowWeb.SearchController do
  @moduledoc """
  Controller for handling search operations and search history management.
  """

  use OverflowWeb, :controller

  alias Overflow.Search

  @doc """
  Performs a search operation with optional preference parameter.

  If a user is authenticated, the search query is automatically saved to their search history.
  The search returns a list of questions from Stack Overflow that match the query.

  This function has multiple clauses:
  1. With both query and preference parameters
  2. With only query parameter (defaults preference to "relevance")
  3. Fallback for invalid parameters

  ## Parameters
    * `conn` - The Plug.Conn struct
    * `params` - Map containing:
      * `"query"` - The search query string (required)
      * `"preference"` - Search preference, defaults to "relevance" (optional)

  ## Returns
    * `200` with search results containing questions on success
    * `400` with error message on failure or invalid parameters

  ## Examples
      POST /api/search
      {
        "query": "How to use Elixir?",
        "preference": "relevance"
      }

      Response (success):
      {
        "results": [
          {
            "question_id": 12345,
            "title": "How to get started with Elixir?",
            "score": 42,
            "answer_count": 5,
            "view_count": 1000,
            "creation_date": 1234567890,
            "tags": ["elixir", "getting-started"]
          }
        ]
      }

      Response (error):
      {
        "error": "Missing or invalid 'query' parameter"
      }
  """
  @spec search(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def search(conn, %{"query" => query, "preference" => _preference}) when is_binary(query) do
    # Save the search question if user is authenticated
    if Map.has_key?(conn.assigns, :current_user) do
      current_user = conn.assigns.current_user

      Search.create_search_question(%{
        question: query,
        user_id: current_user.id
      })
    end

    search_mod = Application.get_env(:overflow, :search_impl, Overflow.Search.Engine)

    case search_mod.search(query) do
      {:ok, results} ->
        json(conn, %{results: results})

      {:error, _reason} ->
        conn
        |> put_status(400)
        |> json(%{error: "Something went wrong"})
    end
  end

  @spec search(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def search(conn, %{"query" => query}) when is_binary(query) do
    search(conn, %{"query" => query, "preference" => "relevance"})
  end

  @spec search(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def search(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{error: "Missing or invalid 'query' parameter"})
  end

  @doc """
  Retrieves the recent search questions for the authenticated user.

  Returns the last 5 search questions ordered by creation time (most recent first).
  Requires user authentication.

  ## Parameters
    * `conn` - The Plug.Conn struct with authenticated user in assigns
    * `params` - Request parameters (not used)

  ## Returns
    * `200` with list of recent questions

  ## Examples
      GET /api/search/recent
      Authorization: Bearer <token>

      Response:
      {
        "questions": [
          {
            "id": "uuid",
            "question": "How to use Elixir?",
            "created_at": "2025-07-16T08:08:57"
          }
        ]
      }
  """
  @spec recent_questions(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def recent_questions(conn, _params) do
    current_user = conn.assigns.current_user
    questions = Search.get_recent_questions_for_user(current_user.id)

    json(conn, %{
      questions:
        Enum.map(questions, fn question ->
          %{
            id: question.id,
            question: question.question,
            created_at: question.inserted_at
          }
        end)
    })
  end

  @doc """
  Retrieves question details and all answers for a specific question ID.

  Fetches both the question details and answers from the configured Q&A provider (e.g., Stack Overflow) 
  for the given question ID. Returns the complete question information along with all available answers.

  ## Parameters
    * `conn` - The Plug.Conn struct
    * `params` - Map containing:
      * `"question_id"` - The question ID to fetch details and answers for (required)

  ## Returns
    * `200` with question details and list of answers on success
    * `400` with error message on failure or invalid parameters
    * `404` if question is not found

  ## Examples
      GET /api/search/answers/12345

      Response (success):
      {
        "question": {
          "question_id": 12345,
          "title": "How to use Elixir?",
          "body": "Question content...",
          "score": 42,
          "view_count": 1000,
          "owner": {...},
          "tags": ["elixir"]
        },
        "answers": [
          {
            "answer_id": 67890,
            "body": "Answer content...",
            "score": 42,
            "is_accepted": true,
            "owner": {...}
          }
        ]
      }

      Response (error):
      {
        "error": "Missing or invalid question_id parameter"
      }
  """
  @spec get_answers(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get_answers(conn, %{"question_id" => question_id}) when is_binary(question_id) do
    qa_provider =
      Application.get_env(:overflow, :qa_provider, Overflow.External.StackOverflow.Provider)

    case Integer.parse(question_id) do
      {id, ""} when is_integer(id) ->
        # Make both API calls concurrently
        question_task = Task.async(fn -> qa_provider.get_question_details(id) end)
        answers_task = Task.async(fn -> qa_provider.get_answers([id]) end)

        # Wait for both results
        question_result = Task.await(question_task, 30_000)
        answers_result = Task.await(answers_task, 30_000)

        case {question_result, answers_result} do
          {{:ok, question}, {:ok, answers}} ->
            json(conn, %{
              question: question,
              answers: answers
            })

          {{:error, :question_not_found}, _} ->
            conn
            |> put_status(404)
            |> json(%{error: "Question not found"})

          {{:error, _}, {:ok, answers}} ->
            # If question fetch fails but answers succeed, return answers only
            json(conn, %{
              question: nil,
              answers: answers,
              warning: "Could not fetch question details"
            })

          {{:ok, question}, {:error, _}} ->
            # If answers fetch fails but question succeeds, return question only
            json(conn, %{
              question: question,
              answers: [],
              warning: "Could not fetch answers"
            })

          {{:error, _}, {:error, _}} ->
            conn
            |> put_status(400)
            |> json(%{error: "Failed to fetch question details and answers"})
        end

      _ ->
        conn
        |> put_status(400)
        |> json(%{error: "Invalid question_id format. Must be a valid integer"})
    end
  end

  @spec get_answers(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get_answers(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{error: "Missing or invalid question_id parameter"})
  end
end
