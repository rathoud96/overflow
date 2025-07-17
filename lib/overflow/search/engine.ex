defmodule Overflow.Search.Engine do
  @moduledoc """
  Search engine implementation that orchestrates the search flow.

  This module handles the core search functionality by delegating
  to the configured Q&A provider (e.g., Stack Overflow).
  """

  @behaviour Overflow.Search.Behaviour

  @qa_provider Application.compile_env(
                 :overflow,
                 :qa_provider,
                 Overflow.External.StackOverflow.Provider
               )

  @doc """
  Performs a search for questions using the configured Q&A provider.

  ## Parameters
    * `query` - The search query string

  ## Returns
    * `{:ok, questions}` - List of questions matching the query
    * `{:error, reason}` - Error if the search fails
  """
  @spec search(String.t()) :: {:ok, list()} | {:error, any()}
  def search(query) do
    @qa_provider.search_questions(query)
  end

  @doc """
  Gets all answers for a specific question ID.

  ## Parameters
    * `question_id` - The Stack Overflow question ID as a string

  ## Returns
    * `{:ok, answers}` - List of answers for the question
    * `{:error, reason}` - Error if the request fails

  ## Examples
      iex> Overflow.Search.Engine.get_answers_for_question("12345678")
      {:ok, [%{"answer_id" => 123, "body" => "...", ...}]}
  """
  @spec get_answers_for_question(String.t()) :: {:ok, list()} | {:error, any()}
  def get_answers_for_question(question_id) when is_binary(question_id) do
    @qa_provider.get_answers([question_id])
  end
end
