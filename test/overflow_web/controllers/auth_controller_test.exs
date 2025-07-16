defmodule OverflowWeb.AuthControllerTest do
  use OverflowWeb.ConnCase, async: true
  alias Overflow.Repo
  alias Overflow.User

  @signup_attrs %{
    email: "test@example.com",
    username: "testuser",
    password: "supersecret"
  }
  @signup_attrs_str %{
    "email" => "test@example.com",
    "username" => "testuser",
    "password" => "supersecret"
  }

  describe "POST /api/signup" do
    test "registers a new user", %{conn: conn} do
      conn = post(conn, "/api/signup", @signup_attrs)

      assert %{"id" => _, "email" => "test@example.com", "username" => "testuser"} =
               json_response(conn, 201)

      assert Repo.get_by(User, email: "test@example.com")
    end

    test "fails with missing fields", %{conn: conn} do
      conn = post(conn, "/api/signup", %{})
      assert %{"errors" => _} = json_response(conn, 422)
    end

    test "fails with duplicate email", %{conn: conn} do
      _ = post(conn, "/api/signup", @signup_attrs)
      conn = post(conn, "/api/signup", @signup_attrs)
      assert %{"errors" => _} = json_response(conn, 422)
    end
  end

  describe "POST /api/login" do
    setup do
      {:ok, _user} = Overflow.Accounts.register_user(@signup_attrs_str)
      :ok
    end

    test "logs in with correct credentials (email)", %{conn: conn} do
      conn = post(conn, "/api/login", %{identifier: "test@example.com", password: "supersecret"})

      assert %{"token" => _, "user" => %{"email" => "test@example.com"}} =
               json_response(conn, 200)
    end

    test "logs in with correct credentials (username)", %{conn: conn} do
      conn = post(conn, "/api/login", %{identifier: "testuser", password: "supersecret"})
      assert %{"token" => _, "user" => %{"username" => "testuser"}} = json_response(conn, 200)
    end

    test "fails with wrong password", %{conn: conn} do
      conn = post(conn, "/api/login", %{identifier: "test@example.com", password: "wrongpass"})
      assert %{"error" => _} = json_response(conn, 401)
    end

    test "fails with unknown user", %{conn: conn} do
      conn = post(conn, "/api/login", %{identifier: "unknown", password: "whatever"})
      assert %{"error" => _} = json_response(conn, 401)
    end
  end
end
