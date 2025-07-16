defmodule OverflowWeb.RerankControllerTest do
  use OverflowWeb.ConnCase

  import Mox

  setup :verify_on_exit!

  test "POST /api/rerank returns reranked answers", %{conn: conn} do
    question = %{"title" => "Q1"}
    answers = [%{"body" => "A1"}, %{"body" => "A2"}]
    preference = "accuracy"

    Overflow.RankingApi
    |> expect(:rerank_with_preference, fn ^question, ^answers, ^preference ->
      {:ok, Enum.reverse(answers)}
    end)

    conn =
      post(conn, "/api/rerank", %{question: question, answers: answers, preference: preference})

    assert json_response(conn, 200)["answers"] == Enum.reverse(answers)
  end

  test "POST /api/rerank returns error on failure", %{conn: conn} do
    Overflow.RankingApi
    |> expect(:rerank_with_preference, fn _, _, _ -> {:error, :fail} end)

    conn = post(conn, "/api/rerank", %{question: %{}, answers: [], preference: "relevance"})
    assert json_response(conn, 400)["error"]
  end
end
