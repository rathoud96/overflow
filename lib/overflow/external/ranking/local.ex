defmodule Overflow.External.Ranking.Local do
  @moduledoc """
  Client for local OpenAI-compatible LLM to rerank answers.

  This module provides functionality to rerank answers using a local
  LLM service that implements OpenAI-compatible API endpoints.
  """

  @behaviour Overflow.External.Ranking.Behaviour

  @doc """
  Reranks answers using a local LLM service.

  ## Parameters
    * `question` - The original question string
    * `answers` - List of answer maps containing "answer_id" and "body" keys
    * `preference` - Ranking preference (default: "relevance")

  ## Returns
    * `{:ok, reordered_answers}` - Successfully reordered answers
    * `{:error, reason}` - If reranking fails
  """
  @spec rerank_answers(String.t(), list(), String.t()) :: {:ok, list()} | {:error, any()}
  def rerank_answers(question, answers, preference \\ "relevance")
      when is_binary(question) and is_list(answers) do
    llm_url = System.get_env("ML_RANKING_URL")

    timeout =
      case System.get_env("ML_RANKING_TIMEOUT") do
        nil ->
          50_000

        timeout_str ->
          case Integer.parse(timeout_str) do
            {timeout_int, _} when timeout_int > 0 -> timeout_int
            _ -> 50_000
          end
      end

    if is_nil(llm_url) or llm_url == "" do
      {:error, :ml_ranking_url_not_configured}
    else
      do_rerank_answers(llm_url, timeout, question, answers, preference)
    end
  end

  # Private helper functions
  defp do_rerank_answers(llm_url, timeout, question, answers, preference) do
    prompt = build_prompt(question, answers, preference)

    body = %{
      "model" => "llama3",
      "messages" => [
        %{
          "role" => "system",
          "content" =>
            "You are a helpful assistant that only returns answer_ids in a list, ordered by preference."
        },
        %{"role" => "user", "content" => prompt}
      ],
      "max_tokens" => 2048,
      "temperature" => 0
    }

    headers = [{"Content-Type", "application/json"}]

    with {:ok, resp} <-
           HTTPoison.post(llm_url, Jason.encode!(body), headers, recv_timeout: timeout),
         {:ok, result} <- Jason.decode(resp.body),
         %{"choices" => [%{"message" => %{"content" => content}} | _]} <- result,
         {:ok, id_list} <- extract_id_list(content, answers),
         {:ok, reordered} <- reorder_answers_by_id(id_list, answers) do
      {:ok, reordered}
    else
      _ -> {:error, :rerank_failed}
    end
  end

  defp build_prompt(question, answers, preference) do
    ids = Enum.map(answers, fn ans -> ans["answer_id"] || ans[:answer_id] end)

    minimal_answers =
      Enum.map(answers, fn ans ->
        %{
          "answer_id" => ans["answer_id"] || ans[:answer_id],
          "body" => String.slice(ans["body"] || ans[:body] || "", 0, 200)
        }
      end)

    """
    Given the following question and a list of answers, return ONLY a JSON array of their answer_ids, ordered by #{preference} to the question.

    IMPORTANT:
    - Use ALL and ONLY the answer_ids provided below.
    - Do NOT invent, drop, or duplicate any answer_id.
    - Output ONLY a JSON array, e.g. [1,2,3]. No extra text.

    Question:
    #{Jason.encode!(question)}

    Answers (each with answer_id and body):
    #{Jason.encode!(minimal_answers)}

    List of answer_ids (for your reference): #{Jason.encode!(ids)}

    Remember: Output ONLY the JSON array, nothing else.
    """
  end

  defp extract_id_list(content, answers) do
    array_json = extract_json_block(content)
    ids = parse_id_list(array_json, content)
    validate_id_list(ids, answers)
  end

  defp extract_json_block(content) do
    case Regex.run(~r/```(?:json)?\s*([\s\S]+?)\s*```/, content, capture: :all_but_first) do
      [block] ->
        case Regex.run(~r/\[.*\]/s, block) do
          [json] -> json
          _ -> block
        end

      _ ->
        case Regex.run(~r/\[.*\]/s, content) do
          [json] -> json
          _ -> nil
        end
    end
  end

  defp parse_id_list(nil, content) do
    Regex.scan(~r/^\d+\.\s*(\d+)/m, content)
    |> Enum.map(fn [_, id] -> String.to_integer(id) end)
  end

  defp parse_id_list(array_json, _content) do
    case Jason.decode(array_json) do
      {:ok, ids} when is_list(ids) -> ids
      _ -> nil
    end
  end

  defp validate_id_list(ids, answers) do
    if is_list(ids) and Enum.all?(ids, fn id -> id_in_answers?(id, answers) end) and
         length(ids) == length(answers) do
      {:ok, ids}
    else
      {:error, :invalid_id_list}
    end
  end

  defp id_in_answers?(id, answers) do
    Enum.any?(answers, fn ans ->
      Map.get(ans, "answer_id") == id or Map.get(ans, :answer_id) == id
    end)
  end

  defp reorder_answers_by_id(id_list, answers) do
    reordered =
      Enum.map(id_list, fn id ->
        Enum.find(answers, fn ans ->
          Map.get(ans, "answer_id") == id or Map.get(ans, :answer_id) == id
        end)
      end)

    if Enum.all?(reordered) and length(reordered) == length(answers),
      do: {:ok, reordered},
      else: {:error, :reorder_failed}
  end
end
