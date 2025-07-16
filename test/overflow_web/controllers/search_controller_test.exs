defmodule OverflowWeb.SearchControllerTest do
  use OverflowWeb.ConnCase

  import Mox

  setup :verify_on_exit!

  test "POST /api/search returns results", %{conn: conn} do
    Overflow.Search
    |> expect(:search, fn "elixir" -> {:ok, [%{"title" => "Elixir Question"}]} end)

    conn = post(conn, "/api/search", %{query: "elixir"})
    assert json_response(conn, 200)["results"] == [%{"title" => "Elixir Question"}]
  end

  test "POST /api/search returns error on failure", %{conn: conn} do
    Overflow.Search
    |> expect(:search, fn _ -> {:error, :something_wrong} end)

    conn = post(conn, "/api/search", %{query: "fail"})
    assert json_response(conn, 400)["error"]
  end
end
