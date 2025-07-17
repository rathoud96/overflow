defmodule Overflow.External.StackOverflow.Provider do
  @moduledoc """
  Stack Overflow API provider implementation.

  Handles all interactions with the Stack Overflow API including
  searching questions, fetching answers, and retrieving question details.
  """

  @behaviour Overflow.External.QAProvider

  @api_url "https://api.stackexchange.com/2.3"
  @site "stackoverflow"
  @default_timeout 30_000

  @doc """
  Searches for questions on Stack Overflow matching the given query.

  ## Parameters
    * `query` - The search query string

  ## Returns
    * `{:ok, questions}` - List of questions matching the query
    * `{:error, reason}` - Error if the search fails
  """
  @spec search_questions(String.t()) :: {:ok, list()} | {:error, any()}
  def search_questions(query) do
    url = "#{@api_url}/search/advanced?order=desc&sort=votes&q=#{URI.encode(query)}&site=#{@site}"
    timeout = Application.get_env(:overflow, :api_timeout, @default_timeout)

    case HTTPoison.get(url, [], recv_timeout: timeout) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"items" => items}} -> {:ok, items}
          error -> {:error, error}
        end

      {:ok, %HTTPoison.Response{status_code: code}} ->
        {:error, {:http_error, code}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Fetches answers for the given question IDs.

  ## Parameters
    * `question_ids` - List of question IDs to fetch answers for

  ## Returns
    * `{:ok, answers}` - List of answers for the questions
    * `{:error, reason}` - Error if the request fails
  """
  @spec get_answers(list()) :: {:ok, list()} | {:error, any()}
  def get_answers(question_ids) when is_list(question_ids) and length(question_ids) > 0 do
    ids = Enum.join(question_ids, ";")
    timeout = Application.get_env(:overflow, :api_timeout, @default_timeout)

    url =
      "#{@api_url}/questions/#{ids}/answers?order=desc&sort=votes&site=#{@site}&filter=withbody"

    case HTTPoison.get(url, [], recv_timeout: timeout) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"items" => items}} ->
            {:ok, items}

          error ->
            {:error, error}
        end

      {:ok, %HTTPoison.Response{status_code: code}} ->
        {:error, {:http_error, code}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec get_answers(any()) :: {:ok, list()}
  def get_answers(_), do: {:ok, []}

  @doc """
  Fetches detailed information for a specific question.

  ## Parameters
    * `question_id` - The question ID to fetch details for

  ## Returns
    * `{:ok, question}` - The question details
    * `{:error, :question_not_found}` - If question doesn't exist
    * `{:error, reason}` - Other errors
  """
  @spec get_question_details(integer()) :: {:ok, map()} | {:error, any()}
  def get_question_details(question_id) when is_integer(question_id) do
    timeout = Application.get_env(:overflow, :api_timeout, @default_timeout)
    url = "#{@api_url}/questions/#{question_id}?site=#{@site}&filter=withbody"

    case HTTPoison.get(url, [], recv_timeout: timeout) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"items" => [question | _]}} ->
            {:ok, question}

          {:ok, %{"items" => []}} ->
            {:error, :question_not_found}

          error ->
            {:error, error}
        end

      {:ok, %HTTPoison.Response{status_code: code}} ->
        {:error, {:http_error, code}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
