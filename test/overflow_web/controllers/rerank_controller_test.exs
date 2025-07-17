defmodule OverflowWeb.RerankControllerTest do
  use OverflowWeb.ConnCase

  import Mox

  setup :verify_on_exit!

  setup do
    Application.put_env(:overflow, :ranking_api_impl, Overflow.RankingApiMock)
    :ok
  end

  describe "POST /api/rerank" do
    test "returns reranked answers with all parameters", %{conn: conn} do
      question = Faker.Lorem.sentence(5..10)

      answers = [
        %{"body" => Faker.Lorem.sentence(10..15)},
        %{"body" => Faker.Lorem.sentence(8..12)},
        %{"body" => Faker.Lorem.sentence(12..18)}
      ]

      preference = "accuracy"

      Overflow.RankingApiMock
      |> expect(:rerank_answers, fn ^question, ^answers, ^preference ->
        {:ok, Enum.reverse(answers)}
      end)

      conn =
        post(conn, "/api/rerank", %{question: question, answers: answers, preference: preference})

      assert json_response(conn, 200)["answers"] == Enum.reverse(answers)
    end

    test "returns reranked answers with default preference", %{conn: conn} do
      question = Faker.Lorem.sentence(3..8)
      answers = [%{"body" => Faker.Lorem.sentence(5..10)}]

      Overflow.RankingApiMock
      |> expect(:rerank_answers, fn ^question, ^answers, "relevance" ->
        {:ok, answers}
      end)

      conn = post(conn, "/api/rerank", %{question: question, answers: answers})
      assert json_response(conn, 200)["answers"] == answers
    end

    test "returns error on ranking failure", %{conn: conn} do
      question = Faker.Lorem.sentence(4..7)
      answers = [%{"body" => Faker.Lorem.sentence(6..12)}]

      Overflow.RankingApiMock
      |> expect(:rerank_answers, fn ^question, ^answers, "relevance" ->
        {:error, :ranking_failed}
      end)

      conn = post(conn, "/api/rerank", %{question: question, answers: answers})
      assert %{"error" => "Reranking failed"} = json_response(conn, 400)
    end

    test "returns error for invalid question type", %{conn: conn} do
      conn = post(conn, "/api/rerank", %{question: %{}, answers: [], preference: "relevance"})

      assert %{"error" => "Missing or invalid required fields: question (string), answers (list)"} =
               json_response(conn, 400)
    end

    test "returns error for missing parameters", %{conn: conn} do
      conn = post(conn, "/api/rerank", %{})

      assert %{"error" => "Missing or invalid required fields: question (string), answers (list)"} =
               json_response(conn, 400)
    end
  end

  describe "POST /api/rerank-structured" do
    test "returns reranked structured data", %{conn: conn} do
      question_data = %{
        "question_id" => Faker.random_between(1, 10000),
        "title" => Faker.Lorem.sentence(3..8),
        "body" => Faker.Lorem.paragraph(2..4),
        "score" => Faker.random_between(0, 100)
      }

      answers = [
        %{
          "answer_id" => Faker.random_between(1, 10000),
          "body" => Faker.Lorem.paragraph(1..3),
          "score" => Faker.random_between(0, 50),
          "is_accepted" => false
        },
        %{
          "answer_id" => Faker.random_between(1, 10000),
          "body" => Faker.Lorem.paragraph(2..4),
          "score" => Faker.random_between(0, 50),
          "is_accepted" => true
        }
      ]

      Overflow.RankingApiMock
      |> expect(:rerank_answers, fn _question_text, ^answers, "relevance" ->
        {:ok, Enum.reverse(answers)}
      end)

      conn =
        post(conn, "/api/rerank-structured", %{
          question: question_data,
          answers: answers,
          preference: "relevance"
        })

      response = json_response(conn, 200)
      assert response["question"] == question_data
      assert response["answers"] == Enum.reverse(answers)
    end

    test "works with default preference", %{conn: conn} do
      question_data = %{"title" => Faker.Lorem.sentence(2..5)}
      answers = [%{"answer_id" => 1, "body" => Faker.Lorem.sentence(5..10)}]

      Overflow.RankingApiMock
      |> expect(:rerank_answers, fn _question_text, ^answers, "relevance" ->
        {:ok, answers}
      end)

      conn = post(conn, "/api/rerank-structured", %{question: question_data, answers: answers})

      response = json_response(conn, 200)
      assert response["question"] == question_data
      assert response["answers"] == answers
    end
  end
end
