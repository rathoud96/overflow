defmodule OverflowWeb.AuthControllerTest do
  use OverflowWeb.ConnCase, async: true
  alias Overflow.Repo
  alias Overflow.Accounts.User

  describe "POST /api/signup" do
    test "registers a new user", %{conn: conn} do
      user_params = %{
        email: Faker.Internet.email(),
        username: Faker.Internet.user_name(),
        password: "supersecret123"
      }

      conn = post(conn, "/api/signup", user_params)

      assert %{
               "token" => _,
               "user" => %{"id" => _, "email" => email, "username" => username}
             } = json_response(conn, 201)

      assert email == user_params.email
      assert username == user_params.username
      assert Repo.get_by(User, email: user_params.email)
    end

    test "fails with missing fields", %{conn: conn} do
      conn = post(conn, "/api/signup", %{})
      assert %{"errors" => _} = json_response(conn, 422)
    end

    test "fails with duplicate email", %{conn: conn} do
      user = insert(:user)

      duplicate_params = %{
        email: user.email,
        username: Faker.Internet.user_name(),
        password: "password123"
      }

      conn = post(conn, "/api/signup", duplicate_params)
      assert %{"errors" => _} = json_response(conn, 422)
    end

    test "fails with duplicate username", %{conn: conn} do
      user = insert(:user)

      duplicate_params = %{
        email: Faker.Internet.email(),
        username: user.username,
        password: "password123"
      }

      conn = post(conn, "/api/signup", duplicate_params)
      assert %{"errors" => _} = json_response(conn, 422)
    end
  end

  describe "POST /api/login" do
    setup do
      user = insert(:user_with_email, password_hash: Bcrypt.hash_pwd_salt("supersecret123"))
      {:ok, user: user}
    end

    test "logs in with correct credentials (email)", %{conn: conn, user: user} do
      conn =
        post(conn, "/api/login", %{"identifier" => user.email, "password" => "supersecret123"})

      assert %{"token" => _, "user" => %{"email" => email}} = json_response(conn, 200)
      assert email == user.email
    end

    test "logs in with correct credentials (username)", %{conn: conn, user: user} do
      conn =
        post(conn, "/api/login", %{"identifier" => user.username, "password" => "supersecret123"})

      assert %{"token" => _, "user" => %{"username" => username}} = json_response(conn, 200)
      assert username == user.username
    end

    test "fails with wrong password", %{conn: conn, user: user} do
      conn =
        post(conn, "/api/login", %{"identifier" => user.email, "password" => "wrongpassword"})

      assert %{"error" => _} = json_response(conn, 401)
    end

    test "fails with unknown user", %{conn: conn} do
      fake_email = Faker.Internet.email()
      conn = post(conn, "/api/login", %{"identifier" => fake_email, "password" => "whatever"})
      assert %{"error" => _} = json_response(conn, 401)
    end

    test "fails with missing fields", %{conn: conn} do
      conn = post(conn, "/api/login", %{})
      assert %{"error" => "Missing required fields: identifier, password"} = json_response(conn, 400)
    end
  end
end
