defmodule Overflow.External.Ranking.MockProvider do
  @moduledoc """
  Mock ranking provider for testing and development purposes.

  This provider simply shuffles the answers randomly or returns them
  in reverse order depending on the preference.
  """

  @behaviour Overflow.External.RankingProvider

  @doc """
  Mock implementation that reranks answers based on simple rules.

  ## Preferences
    * "relevance" - Returns answers in reverse order
    * "random" - Shuffles answers randomly
    * Any other preference - Returns answers as-is
  """
  @spec rerank_answers(String.t(), list(), String.t()) :: {:ok, list()} | {:error, any()}
  def rerank_answers(_question, answers, preference) when is_list(answers) do
    reordered =
      case preference do
        "relevance" -> Enum.reverse(answers)
        "random" -> Enum.shuffle(answers)
        _ -> answers
      end

    {:ok, reordered}
  end
end
