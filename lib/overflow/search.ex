defmodule Overflow.Search do
  @moduledoc """
  Orchestrates the search flow: Q&A provider -> ML reranking -> response.
  """

  @qa_provider Application.compile_env(:overflow, :qa_provider, Overflow.StackOverflowProvider)

  def search(query) do
    with {:ok, questions} <- @qa_provider.search_questions(query),
         question_ids when is_list(question_ids) <- extract_question_ids(questions),
         {:ok, answers} <- fetch_answers(question_ids) do
      {:ok, answers}
    else
      {:error, _} = err -> err
      _ -> {:error, :unexpected}
    end
  end

  defp extract_question_ids(questions) do
    questions
    |> Enum.map(& &1["question_id"])
    |> Enum.filter(& &1)
    |> Enum.uniq()
  end

  defp fetch_answers([]), do: {:ok, []}
  defp fetch_answers(question_ids), do: @qa_provider.get_answers(question_ids)
end
