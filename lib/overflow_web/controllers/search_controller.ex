defmodule OverflowWeb.SearchController do
  use OverflowWeb, :controller

  def search(conn, %{"q" => query, "preference" => preference}) do
    case Overflow.Search.search_questions(query, preference) do
      {:ok, results} ->
        json(conn, %{results: results})

      {:error, reason} ->
        conn
        |> put_status(500)
        |> json(%{error: to_string(reason)})
    end
  end

  def search(conn, %{"q" => query}) do
    search(conn, %{"q" => query, "preference" => "relevance"})
  end
end
