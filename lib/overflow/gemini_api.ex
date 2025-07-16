defmodule Overflow.GeminiApi do
  @moduledoc """
  Client for the Gemini API to rerank answers.
  """

  def rerank_answers(question, answers, preference \\ "relevance")
      when is_binary(question) and is_list(answers) do
    api_key = Application.get_env(:overflow, :gemini)[:api_key]
    gemini_url = Application.get_env(:overflow, :gemini)[:api_url]
    timeout = 50_000
    prompt = build_prompt(question, answers, preference)

    body = %{
      "contents" => [
        %{"role" => "user", "parts" => [%{text: prompt}]}
      ]
    }

    headers = [
      {"Content-Type", "application/json"}
    ]

    url = gemini_url <> "?key=" <> api_key
    IO.inspect(url, label: "url")

    with {:ok, resp} <- HTTPoison.post(url, Jason.encode!(body), headers, recv_timeout: timeout),
         IO.inspect(resp, label: "resp"),
         {:ok, result} <- Jason.decode(resp.body),
         %{"candidates" => [%{"content" => %{"parts" => [%{"text" => content}]}} | _]} <- result,
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
    # Try to extract JSON array inside a code block first
    array_json =
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

    ids =
      cond do
        array_json != nil ->
          case Jason.decode(array_json) do
            {:ok, ids} when is_list(ids) -> ids
            _ -> nil
          end

        true ->
          Regex.scan(~r/^\d+\.\s*(\d+)/m, content)
          |> Enum.map(fn [_, id] -> String.to_integer(id) end)
      end

    if is_list(ids) and Enum.all?(ids, fn id -> is_id_in_answers?(id, answers) end) and
         length(ids) == length(answers) do
      {:ok, ids}
    else
      {:error, :invalid_id_list}
    end
  end

  defp is_id_in_answers?(id, answers) do
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
