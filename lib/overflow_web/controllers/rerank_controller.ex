defmodule OverflowWeb.RerankController do
  @moduledoc """
  Controller for handling answer reranking operations.

  Provides functionality to reorder answers based on relevance or other preferences
  using the configured ranking implementation.
  """

  use OverflowWeb, :controller

  @doc """
  Reranks a list of answers based on a question and preference.

  Takes a question, list of answers, and a preference to reorder the answers
  according to the specified ranking criteria.

  This function has multiple clauses:
  1. With question, answers, and preference parameters
  2. With only question and answers (defaults preference to "relevance")
  3. Fallback for invalid parameters

  ## Parameters
    * `conn` - The Plug.Conn struct
    * `params` - Map containing:
      * `"question"` - The question string (required)
      * `"answers"` - List of answer strings (required)
      * `"preference"` - Ranking preference (optional, defaults to "relevance")

  ## Returns
    * `200` with reordered answers on success
    * `400` with error message on failure or invalid parameters

  ## Examples
      POST /api/rerank
      {
        "question": "How to use Elixir?",
        "answers": ["Answer 1", "Answer 2", "Answer 3"],
        "preference": "relevance"
      }

      Response (success):
      {
        "answers": ["Answer 2", "Answer 1", "Answer 3"]
      }

      Response (error):
      {
        "error": "Missing or invalid required fields: question (string), answers (list)"
      }
  """
  @spec rerank(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def rerank(conn, %{"question" => question, "answers" => answers, "preference" => preference})
      when is_binary(question) and is_list(answers) and is_binary(preference) do
    ranking_mod = Application.get_env(:overflow, :ranking_api_impl, Overflow.External.Ranking.API)

    case ranking_mod.rerank_answers(question, answers, preference) do
      {:ok, reordered} ->
        json(conn, %{answers: reordered})

      {:error, _reason} ->
        conn
        |> put_status(400)
        |> json(%{error: "Reranking failed"})
    end
  end

  @spec rerank(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def rerank(conn, %{"question" => question, "answers" => answers})
      when is_binary(question) and is_list(answers) do
    rerank(conn, %{"question" => question, "answers" => answers, "preference" => "relevance"})
  end

  @spec rerank(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def rerank(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{error: "Missing or invalid required fields: question (string), answers (list)"})
  end

  @doc """
  Reranks answers while preserving question data structure.

  Takes the same structure returned by `/search/answers/:question_id` endpoint
  (containing both question and answers) and reranks the answers while keeping
  the question data intact.

  ## Parameters
    * `conn` - The Plug.Conn struct
    * `params` - Map containing:
      * `"question"` - Question object with title, body, etc. (required)
      * `"answers"` - List of answer objects with answer_id, body, etc. (required)
      * `"preference"` - Ranking preference (optional, defaults to "relevance")

  ## Returns
    * `200` with question object and reordered answers on success
    * `400` with error message on failure or invalid parameters

  ## Examples
      POST /api/rerank-structured
      {
        "question": {
          "question_id": 12345,
          "title": "How to use Elixir?",
          "body": "...",
          "score": 42
        },
        "answers": [
          {
            "answer_id": 67890,
            "body": "Answer content...",
            "score": 42,
            "is_accepted": true
          }
        ],
        "preference": "relevance"
      }

      Response (success):
      {
        "question": {
          "question_id": 12345,
          "title": "How to use Elixir?",
          "body": "...",
          "score": 42
        },
        "answers": [
          {
            "answer_id": 67890,
            "body": "Answer content...",
            "score": 42,
            "is_accepted": true
          }
        ]
      }
  """
  @spec rerank_structured(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def rerank_structured(conn, %{
        "question" => question,
        "answers" => answers,
        "preference" => preference
      })
      when is_map(question) and is_list(answers) and is_binary(preference) do
    # Extract question title or use question_id as fallback for ranking
    question_text = get_question_text(question)

    ranking_mod = Application.get_env(:overflow, :ranking_api_impl, Overflow.External.Ranking.API)

    case ranking_mod.rerank_answers(question_text, answers, preference) do
      {:ok, reordered} ->
        json(conn, %{
          question: question,
          answers: reordered
        })

      {:error, _reason} ->
        conn
        |> put_status(400)
        |> json(%{error: "Reranking failed"})
    end
  end

  @spec rerank_structured(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def rerank_structured(conn, %{"question" => question, "answers" => answers})
      when is_map(question) and is_list(answers) do
    rerank_structured(conn, %{
      "question" => question,
      "answers" => answers,
      "preference" => "relevance"
    })
  end

  @spec rerank_structured(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def rerank_structured(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{error: "Missing or invalid required fields: question (object), answers (list)"})
  end

  # Private helper function to extract question text for ranking
  defp get_question_text(question) when is_map(question) do
    question
    |> extract_title()
    |> case do
      nil -> extract_body_or_fallback(question)
      title -> title
    end
  end

  defp extract_title(question) do
    question["title"] || question[:title]
  end

  defp extract_body_or_fallback(question) do
    case question["body"] || question[:body] do
      body when is_binary(body) -> String.slice(body, 0, 200)
      _ -> build_fallback_text(question)
    end
  end

  defp build_fallback_text(question) do
    question_id = question["question_id"] || question[:question_id] || "unknown"
    "Question #{question_id}"
  end
end
