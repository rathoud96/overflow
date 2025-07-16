defmodule Overflow.QAProvider do
  @moduledoc """
  Behaviour for Q&A provider modules (e.g., Stack Overflow, Quora, etc.)
  """

  @callback search_questions(query :: String.t()) :: {:ok, list()} | {:error, any()}
  @callback get_answers(answer_ids :: list()) :: {:ok, list()} | {:error, any()}
end
