defmodule Overflow.External.QAProvider do
  @moduledoc """
  Behaviour for Q&A provider modules.

  Defines the contract that all Q&A providers (e.g., Stack Overflow, Quora, etc.)
  must implement to be compatible with the search system.
  """

  @doc """
  Searches for questions matching the given query.
  """
  @callback search_questions(query :: String.t()) :: {:ok, list()} | {:error, any()}

  @doc """
  Fetches answers for the given question IDs.
  """
  @callback get_answers(question_ids :: list()) :: {:ok, list()} | {:error, any()}

  @doc """
  Fetches detailed information for a specific question.
  """
  @callback get_question_details(question_id :: integer()) :: {:ok, map()} | {:error, any()}
end
