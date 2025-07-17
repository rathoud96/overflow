defmodule Overflow.Factory do
  @moduledoc """
  Factory module for generating test data using ExMachina.

  Provides factories for creating test instances of:
  - User accounts
  - Search questions
  """

  use ExMachina.Ecto, repo: Overflow.Repo

  def user_factory do
    %Overflow.Accounts.User{
      email: sequence(:email, &"user#{&1}@example.com"),
      username: sequence(:username, &"user#{&1}"),
      password_hash: Bcrypt.hash_pwd_salt("password123")
    }
  end

  def user_with_email_factory do
    %Overflow.Accounts.User{
      email: Faker.Internet.email(),
      username: Faker.Internet.user_name(),
      password_hash: Bcrypt.hash_pwd_salt("password123")
    }
  end

  def search_question_factory do
    %Overflow.Search.Question{
      question: Faker.Lorem.sentence(10..20),
      user: build(:user)
    }
  end

  def search_question_with_user_factory do
    %Overflow.Search.Question{
      question: sequence(:question, &"How to #{Faker.Lorem.word()}? #{&1}"),
      user: insert(:user)
    }
  end

  # Helper functions for common patterns
  def user_with_search_questions_factory do
    user = insert(:user)

    insert_list(3, :search_question, user: user)

    user
  end

  # Factory for creating users with specific attributes
  def admin_user_factory do
    %Overflow.Accounts.User{
      email: "admin@example.com",
      username: "admin",
      password_hash: Bcrypt.hash_pwd_salt("admin123")
    }
  end

  # Factory for creating realistic programming questions
  def programming_question_factory do
    questions = [
      "How to implement recursion in Elixir?",
      "What is the difference between processes and threads?",
      "How to handle errors in Phoenix controllers?",
      "What are GenServers used for?",
      "How to optimize database queries in Ecto?",
      "What is pattern matching in functional programming?",
      "How to deploy a Phoenix application?",
      "What are the benefits of using OTP?",
      "How to write effective unit tests?",
      "What is the Actor model in Elixir?"
    ]

    %Overflow.Search.Question{
      question: Enum.random(questions),
      user: build(:user)
    }
  end
end
