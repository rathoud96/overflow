defmodule Overflow.External.Ranking.Behaviour do
  @moduledoc """
  Behaviour for ranking API implementations.
  """

  @callback rerank_answers(String.t(), list(), String.t()) :: {:ok, list()} | {:error, any()}
end

defmodule Overflow.External.Ranking.API do
  @moduledoc """
  Reranking API dispatcher.

  Routes reranking requests to the appropriate backend
  (local LLM or Gemini) based on configuration.
  """

  alias Overflow.External.Gemini.API, as: GeminiAPI
  alias Overflow.External.Ranking.Local

  @behaviour Overflow.External.Ranking.Behaviour

  @doc """
  Reranks answers based on configured backend.

  ## Parameters
    * `question` - The original question
    * `answers` - List of answers to rerank
    * `preference` - Ranking preference (default: "relevance")

  ## Returns
    * `{:ok, reordered_answers}` - Successfully reordered answers
    * `{:error, reason}` - If reranking fails
  """
  @spec rerank_answers(String.t(), list(), String.t()) :: {:ok, list()} | {:error, any()}
  def rerank_answers(question, answers, preference \\ "relevance") do
    backend = Application.get_env(:overflow, :rerank_backend, :local)
    case backend do
      :local -> Local.rerank_answers(question, answers, preference)
      :gemini -> GeminiAPI.rerank_answers(question, answers, preference)
      _ -> {:error, :invalid_backend}
    end
  end
end
