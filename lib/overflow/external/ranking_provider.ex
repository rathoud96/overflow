defmodule Overflow.External.RankingProvider do
  @moduledoc """
  Behaviour for ranking provider modules.

  Defines the contract that all ranking providers (e.g., Local LLM, Gemini, etc.)
  must implement to be compatible with the reranking system.
  """

  @doc """
  Reranks a list of answers based on a question and preference.

  ## Parameters
    * `question` - The original question string
    * `answers` - List of answer maps or strings to rerank
    * `preference` - Ranking preference (e.g., "relevance", "popularity", etc.)

  ## Returns
    * `{:ok, reordered_answers}` - Successfully reordered answers
    * `{:error, reason}` - If reranking fails
  """
  @callback rerank_answers(question :: String.t(), answers :: list(), preference :: String.t()) ::
              {:ok, list()} | {:error, any()}
end
