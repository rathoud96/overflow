defmodule Overflow.StackOverflowProvider do
  @behaviour Overflow.QAProvider

  @api_url "https://api.stackexchange.com/2.3"
  @site "stackoverflow"

  def search_questions(query) do
    url = "#{@api_url}/search/advanced?order=desc&sort=votes&q=#{URI.encode(query)}&site=#{@site}"

    case HTTPoison.get(url) do
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

  def get_answers(question_ids) when is_list(question_ids) and length(question_ids) > 0 do
    ids = Enum.join(question_ids, ";")

    url =
      "#{@api_url}/questions/#{ids}/answers?order=desc&sort=votes&site=#{@site}&filter=withbody"

    case HTTPoison.get(url) do
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

  def get_answers(_), do: {:ok, []}
end
