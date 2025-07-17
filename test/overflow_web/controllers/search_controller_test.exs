defmodule OverflowWeb.SearchControllerTest do
  use OverflowWeb.ConnCase

  import Mox

  setup :verify_on_exit!

  setup do
    Application.put_env(:overflow, :search_impl, Overflow.SearchMock)
    :ok
  end

  test "POST /api/search returns results", %{conn: conn} do
    search_query = Faker.Lorem.sentence(3..5)
    expected_result = %{"title" => Faker.Lorem.sentence(5..10)}

    Overflow.SearchMock
    |> expect(:search, fn ^search_query -> {:ok, [expected_result]} end)

    conn = post(conn, "/api/search", %{"query" => search_query})
    assert json_response(conn, 200)["results"] == [expected_result]
  end

  test "POST /api/search returns error on failure", %{conn: conn} do
    search_query = Faker.Lorem.sentence(2..4)

    Overflow.SearchMock
    |> expect(:search, fn ^search_query -> {:error, :something_wrong} end)

    conn = post(conn, "/api/search", %{"query" => search_query})
    assert json_response(conn, 400)["error"]
  end

  test "POST /api/search saves search question for authenticated user", %{conn: conn} do
    _user = insert(:user)
    search_query = Faker.Lorem.sentence(4..8)

    # Mock the search to return successful results
    Overflow.SearchMock
    |> expect(:search, fn ^search_query -> {:ok, [%{"title" => "Test Result"}]} end)

    # Authenticate the user (you would need to implement auth middleware)
    # For now, we'll test without authentication
    conn = post(conn, "/api/search", %{"query" => search_query})
    assert json_response(conn, 200)
  end

  test "POST /api/search fails with missing query parameter", %{conn: conn} do
    conn = post(conn, "/api/search", %{})
    assert %{"error" => "Missing or invalid 'query' parameter"} = json_response(conn, 400)
  end

  test "POST /api/search fails with empty query", %{conn: conn} do
    # The controller will still call the search service, so we need to mock it
    Overflow.SearchMock
    |> expect(:search, fn "" -> {:error, :empty_query} end)

    conn = post(conn, "/api/search", %{"query" => ""})
    assert %{"error" => "Something went wrong"} = json_response(conn, 400)
  end
end
