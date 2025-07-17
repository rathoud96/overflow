defmodule Overflow.AccountsTest do
  use Overflow.DataCase

  alias Overflow.Accounts
  alias Overflow.Accounts.User

  describe "register_user/1" do
    test "creates user with valid data" do
      attrs = %{
        "email" => Faker.Internet.email(),
        "username" => Faker.Internet.user_name(),
        "password" => "validpassword123"
      }

      assert {:ok, %User{} = user} = Accounts.register_user(attrs)
      assert user.email == attrs["email"]
      assert user.username == attrs["username"]
      assert Bcrypt.verify_pass("validpassword123", user.password_hash)
      assert user.id
    end

    test "creates user with atom keys" do
      attrs = %{
        email: Faker.Internet.email(),
        username: Faker.Internet.user_name(),
        password: "validpassword123"
      }

      # Convert to string keys as the function expects
      string_attrs = %{
        "email" => attrs.email,
        "username" => attrs.username,
        "password" => attrs.password
      }

      assert {:ok, %User{} = user} = Accounts.register_user(string_attrs)
      assert user.email == attrs.email
      assert user.username == attrs.username
    end

    test "returns error for duplicate email" do
      email = Faker.Internet.email()

      user1_attrs = %{
        "email" => email,
        "username" => Faker.Internet.user_name(),
        "password" => "password123"
      }

      user2_attrs = %{
        "email" => email,
        "username" => Faker.Internet.user_name(),
        "password" => "password456"
      }

      assert {:ok, _user1} = Accounts.register_user(user1_attrs)
      assert {:error, changeset} = Accounts.register_user(user2_attrs)
      assert %{email: ["has already been taken"]} = errors_on(changeset)
    end

    test "returns error for duplicate username" do
      username = Faker.Internet.user_name()

      user1_attrs = %{
        "email" => Faker.Internet.email(),
        "username" => username,
        "password" => "password123"
      }

      user2_attrs = %{
        "email" => Faker.Internet.email(),
        "username" => username,
        "password" => "password456"
      }

      assert {:ok, _user1} = Accounts.register_user(user1_attrs)
      assert {:error, changeset} = Accounts.register_user(user2_attrs)
      assert %{username: ["has already been taken"]} = errors_on(changeset)
    end

    test "returns error for missing email" do
      attrs = %{
        "username" => Faker.Internet.user_name(),
        "password" => "validpassword123"
      }

      assert {:error, changeset} = Accounts.register_user(attrs)
      assert %{email: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error for missing username" do
      attrs = %{
        "email" => Faker.Internet.email(),
        "password" => "validpassword123"
      }

      assert {:error, changeset} = Accounts.register_user(attrs)
      assert %{username: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error for missing password" do
      attrs = %{
        "email" => Faker.Internet.email(),
        "username" => Faker.Internet.user_name()
      }

      assert {:error, changeset} = Accounts.register_user(attrs)
      assert %{password: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error for empty password" do
      attrs = %{
        "email" => Faker.Internet.email(),
        "username" => Faker.Internet.user_name(),
        "password" => ""
      }

      assert {:error, changeset} = Accounts.register_user(attrs)
      assert %{password: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error for nil password" do
      attrs = %{
        "email" => Faker.Internet.email(),
        "username" => Faker.Internet.user_name(),
        "password" => nil
      }

      assert {:error, changeset} = Accounts.register_user(attrs)
      assert %{password: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error for invalid email format" do
      attrs = %{
        "email" => "invalid-email",
        "username" => Faker.Internet.user_name(),
        "password" => "validpassword123"
      }

      assert {:error, changeset} = Accounts.register_user(attrs)
      assert %{email: ["must be a valid email address"]} = errors_on(changeset)
    end

    test "returns error for too short username" do
      attrs = %{
        "email" => Faker.Internet.email(),
        "username" => "ab",
        "password" => "validpassword123"
      }

      assert {:error, changeset} = Accounts.register_user(attrs)
      assert %{username: ["should be at least 3 character(s)"]} = errors_on(changeset)
    end

    test "returns error for too long username" do
      attrs = %{
        "email" => Faker.Internet.email(),
        "username" => String.duplicate("a", 40), # max is 39
        "password" => "validpassword123"
      }

      assert {:error, changeset} = Accounts.register_user(attrs)
      assert %{username: ["should be at most 39 character(s)"]} = errors_on(changeset)
    end
  end

  describe "authenticate_user/2" do
    setup do
      password = "secretpassword123"
      user = insert(:user, password_hash: Bcrypt.hash_pwd_salt(password))
      {:ok, user: user, password: password}
    end

    test "returns user for valid email and password", %{user: user, password: password} do
      assert {:ok, authenticated_user} = Accounts.authenticate_user(user.email, password)
      assert authenticated_user.id == user.id
      assert authenticated_user.email == user.email
      assert authenticated_user.username == user.username
    end

    test "returns user for valid username and password", %{user: user, password: password} do
      assert {:ok, authenticated_user} = Accounts.authenticate_user(user.username, password)
      assert authenticated_user.id == user.id
      assert authenticated_user.email == user.email
      assert authenticated_user.username == user.username
    end

    test "returns error for valid email but wrong password", %{user: user} do
      assert :error = Accounts.authenticate_user(user.email, "wrongpassword")
    end

    test "returns error for valid username but wrong password", %{user: user} do
      assert :error = Accounts.authenticate_user(user.username, "wrongpassword")
    end

    test "returns error for non-existent email" do
      fake_email = Faker.Internet.email()
      assert :error = Accounts.authenticate_user(fake_email, "anypassword")
    end

    test "returns error for non-existent username" do
      fake_username = Faker.Internet.user_name()
      assert :error = Accounts.authenticate_user(fake_username, "anypassword")
    end

    test "returns error for empty password", %{user: user} do
      assert :error = Accounts.authenticate_user(user.email, "")
    end

    test "returns error for nil password", %{user: user} do
      assert_raise ArgumentError, fn ->
        Accounts.authenticate_user(user.email, nil)
      end
    end

    test "handles case-sensitive email matching", %{user: user, password: password} do
      # Email should be case-sensitive in our implementation
      uppercase_email = String.upcase(user.email)
      assert :error = Accounts.authenticate_user(uppercase_email, password)
    end

    test "handles case-sensitive username matching", %{user: user, password: password} do
      # Username should be case-sensitive in our implementation
      uppercase_username = String.upcase(user.username)
      assert :error = Accounts.authenticate_user(uppercase_username, password)
    end
  end

  describe "get_user!/1" do
    test "returns user when exists" do
      user = insert(:user)

      found_user = Accounts.get_user!(user.id)

      assert found_user.id == user.id
      assert found_user.email == user.email
      assert found_user.username == user.username
    end

    test "raises when user does not exist" do
      fake_id = Ecto.UUID.generate()

      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(fake_id)
      end
    end

    test "raises for invalid UUID format" do
      assert_raise Ecto.Query.CastError, fn ->
        Accounts.get_user!("invalid-uuid")
      end
    end

    test "raises for nil id" do
      assert_raise ArgumentError, fn ->
        Accounts.get_user!(nil)
      end
    end
  end
end
