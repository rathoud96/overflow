defmodule OverflowWeb.RerankController do
  use OverflowWeb, :controller

  def rerank(conn, %{"question" => question, "answers" => answers, "preference" => preference}) do
    case Overflow.RankingApi.rerank_answers(question, answers, preference) do
      {:ok, reordered} ->
        json(conn, %{answers: reordered})

      {:error, reason} ->
        conn
        |> put_status(500)
        |> json(%{error: to_string(reason)})
    end
  end

  def rerank(conn, %{"question" => question, "answers" => answers}) do
    rerank(conn, %{"question" => question, "answers" => answers, "preference" => "relevance"})
  end
end
