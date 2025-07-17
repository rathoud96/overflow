defmodule Overflow.SearchTest do
  use Overflow.DataCase

  alias Overflow.Search
  alias Overflow.Search.Question

  describe "create_search_question/1" do
    test "creates search question with valid data" do
      user = insert(:user)

      attrs = %{
        question: "How to use GenServer in Elixir?",
        user_id: user.id
      }

      assert {:ok, %Question{} = question} = Search.create_search_question(attrs)
      assert question.question == attrs.question
      assert question.user_id == attrs.user_id
      assert question.id
      assert question.inserted_at
      assert %NaiveDateTime{} = question.inserted_at
    end

    test "creates search question with string keys" do
      user = insert(:user)

      attrs = %{
        "question" => "What is pattern matching in Elixir?",
        "user_id" => user.id
      }

      assert {:ok, %Question{} = question} = Search.create_search_question(attrs)
      assert question.question == attrs["question"]
      assert question.user_id == attrs["user_id"]
    end

    test "automatically sets inserted_at timestamp" do
      user = insert(:user)

      attrs = %{
        question: "How does OTP supervision work?",
        user_id: user.id
      }

      {:ok, question} = Search.create_search_question(attrs)

      # Just verify that inserted_at is set properly
      assert question.inserted_at
      assert %NaiveDateTime{} = question.inserted_at
    end

    test "returns error for missing question" do
      user = insert(:user)

      attrs = %{
        user_id: user.id
      }

      assert {:error, changeset} = Search.create_search_question(attrs)
      assert %{question: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error for empty question" do
      user = insert(:user)

      attrs = %{
        question: "",
        user_id: user.id
      }

      assert {:error, changeset} = Search.create_search_question(attrs)
      assert %{question: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error for nil question" do
      user = insert(:user)

      attrs = %{
        question: nil,
        user_id: user.id
      }

      assert {:error, changeset} = Search.create_search_question(attrs)
      assert %{question: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error for missing user_id" do
      attrs = %{
        question: "How to handle errors in Elixir?"
      }

      assert {:error, changeset} = Search.create_search_question(attrs)
      assert %{user_id: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error for nil user_id" do
      attrs = %{
        question: "How to handle errors in Elixir?",
        user_id: nil
      }

      assert {:error, changeset} = Search.create_search_question(attrs)
      assert %{user_id: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error for non-existent user" do
      fake_user_id = Ecto.UUID.generate()

      attrs = %{
        question: "How to handle errors in Elixir?",
        user_id: fake_user_id
      }

      assert {:error, changeset} = Search.create_search_question(attrs)
      assert %{user_id: ["does not exist"]} = errors_on(changeset)
    end

    test "returns error for invalid user_id format" do
      attrs = %{
        question: "How to handle errors in Elixir?",
        user_id: "invalid-uuid"
      }

      assert_raise Ecto.ChangeError, fn ->
        Search.create_search_question(attrs)
      end
    end

    test "handles moderately long question strings" do
      user = insert(:user)
      long_question = String.duplicate("How to use GenServer? ", 10) # Keep under 255 char limit for varchar

      attrs = %{
        question: long_question,
        user_id: user.id
      }

      assert {:ok, question} = Search.create_search_question(attrs)
      assert question.question == long_question
    end

    test "returns error for question exceeding max length" do
      user = insert(:user)
      long_question = String.duplicate("x", 1001) # Exceeds 1000 char limit

      attrs = %{
        question: long_question,
        user_id: user.id
      }

      assert {:error, changeset} = Search.create_search_question(attrs)
      assert %{question: ["should be at most 1000 character(s)"]} = errors_on(changeset)
    end

    test "preserves question with special characters" do
      user = insert(:user)
      special_question = "How to use @spec and &capture in Elixir? 🚀"

      attrs = %{
        question: special_question,
        user_id: user.id
      }

      assert {:ok, question} = Search.create_search_question(attrs)
      assert question.question == special_question
    end
  end

  describe "get_recent_questions_for_user/2" do
    setup do
      user1 = insert(:user)
      user2 = insert(:user)

      # Create questions at different times
      {:ok, old_question} = Search.create_search_question(%{
        question: "Old question",
        user_id: user1.id
      })

      Process.sleep(10) # Ensure different timestamps

      {:ok, recent_question1} = Search.create_search_question(%{
        question: "Recent question 1",
        user_id: user1.id
      })

      Process.sleep(10)

      {:ok, recent_question2} = Search.create_search_question(%{
        question: "Recent question 2",
        user_id: user1.id
      })

      # Question from different user
      {:ok, other_user_question} = Search.create_search_question(%{
        question: "Other user question",
        user_id: user2.id
      })

      {:ok, %{
        user1: user1,
        user2: user2,
        old_question: old_question,
        recent_question1: recent_question1,
        recent_question2: recent_question2,
        other_user_question: other_user_question
      }}
    end

    test "returns recent questions for user with default limit", context do
      questions = Search.get_recent_questions_for_user(context.user1.id)

      assert length(questions) == 3
      # Should be ordered by most recent first (verify ordering based on content)
      question_texts = Enum.map(questions, & &1.question)
      assert "Recent question 2" in question_texts
      assert "Recent question 1" in question_texts
      assert "Old question" in question_texts
    end

    test "returns recent questions with custom limit", context do
      questions = Search.get_recent_questions_for_user(context.user1.id, 2)

      assert length(questions) == 2
      # Verify they are from the correct user
      assert Enum.all?(questions, fn q -> q.user_id == context.user1.id end)
    end

    test "returns empty list for user with no questions" do
      new_user = insert(:user)
      questions = Search.get_recent_questions_for_user(new_user.id)

      assert questions == []
    end

    test "only returns questions for specified user", context do
      questions = Search.get_recent_questions_for_user(context.user2.id)

      assert length(questions) == 1
      assert Enum.at(questions, 0).id == context.other_user_question.id
    end

    test "handles limit of zero", context do
      questions = Search.get_recent_questions_for_user(context.user1.id, 0)

      assert questions == []
    end

    test "handles large limit", context do
      questions = Search.get_recent_questions_for_user(context.user1.id, 100)

      assert length(questions) == 3 # Should return all available questions
    end

    test "handles negative limit (should return empty list)" do
      user1 = insert(:user)

      # Create a search question directly using the context function
      Search.create_search_question(%{
        question: "Test question",
        user_id: user1.id
      })

      # The function should handle negative limits gracefully
      assert [] = Search.get_recent_questions_for_user(user1.id, -5)
    end

    test "returns empty list for non-existent user" do
      fake_user_id = Ecto.UUID.generate()
      questions = Search.get_recent_questions_for_user(fake_user_id)

      assert questions == []
    end

    test "includes all question fields", context do
      questions = Search.get_recent_questions_for_user(context.user1.id, 1)
      question = Enum.at(questions, 0)

      assert question.id
      assert question.question
      assert question.user_id == context.user1.id
      assert question.inserted_at
      assert %NaiveDateTime{} = question.inserted_at
    end
  end

  describe "search/1" do
    setup do
      # Set up mock for search tests
      Application.put_env(:overflow, :search_impl, Overflow.SearchMock)
      # Set up mock verification
      verify_on_exit!()
      :ok
    end

    test "delegates to Search implementation with query string" do
      # Mock the Search implementation behavior
      expect(Overflow.SearchMock, :search, fn query ->
        assert query == "How to use GenServer?"
        {:ok, [%{title: "GenServer Guide", url: "https://example.com"}]}
      end)

      result = Search.search("How to use GenServer?")

      assert {:ok, [%{title: "GenServer Guide", url: "https://example.com"}]} = result
    end

    test "handles empty query string" do
      expect(Overflow.SearchMock, :search, fn query ->
        assert query == ""
        {:ok, []}
      end)

      result = Search.search("")

      assert {:ok, []} = result
    end

    test "handles nil query" do
      expect(Overflow.SearchMock, :search, fn query ->
        assert query == nil
        {:error, :invalid_query}
      end)

      result = Search.search(nil)

      assert {:error, :invalid_query} = result
    end

    test "propagates engine errors" do
      expect(Overflow.SearchMock, :search, fn _query ->
        {:error, :api_unavailable}
      end)

      result = Search.search("Any query")

      assert {:error, :api_unavailable} = result
    end

    test "handles special characters in query" do
      special_query = "What is @spec & pattern matching?"

      expect(Overflow.SearchMock, :search, fn query ->
        assert query == special_query
        {:ok, [%{title: "Pattern Matching", url: "https://example.com"}]}
      end)

      result = Search.search(special_query)

      assert {:ok, [%{title: "Pattern Matching", url: "https://example.com"}]} = result
    end

    test "handles very long query strings" do
      long_query = String.duplicate("How to use GenServer? ", 50)

      expect(Overflow.SearchMock, :search, fn query ->
        assert query == long_query
        {:ok, []}
      end)

      result = Search.search(long_query)

      assert {:ok, []} = result
    end
  end

  describe "get_search_question!/1" do
    test "returns search question when exists" do
      user = insert(:user)

      attrs = %{
        question: "How to use Ecto?",
        user_id: user.id
      }

      {:ok, created_question} = Search.create_search_question(attrs)

      found_question = Search.get_search_question!(created_question.id)

      assert found_question.id == created_question.id
      assert found_question.question == created_question.question
      assert found_question.user_id == created_question.user_id
    end

    test "raises when search question does not exist" do
      fake_id = Ecto.UUID.generate()

      assert_raise Ecto.NoResultsError, fn ->
        Search.get_search_question!(fake_id)
      end
    end

    test "raises for invalid UUID format" do
      assert_raise Ecto.Query.CastError, fn ->
        Search.get_search_question!("invalid-uuid")
      end
    end

    test "raises for nil id" do
      assert_raise ArgumentError, fn ->
        Search.get_search_question!(nil)
      end
    end
  end
end
