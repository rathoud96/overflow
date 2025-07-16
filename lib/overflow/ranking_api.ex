defmodule Overflow.RankingApi do
  @moduledoc """
  Reranking API dispatcher. Uses local LLM or Gemini based on config.
  """

  def rerank_answers(question, answers, preference \\ "relevance") do
    backend = Application.get_env(:overflow, :rerank_backend, :local)

    case backend do
      :local -> Overflow.RankingApi.Local.rerank_answers(question, answers, preference)
      :gemini -> Overflow.GeminiApi.rerank_answers(question, answers, preference)
      _ -> {:error, :invalid_backend}
    end
  end
end
