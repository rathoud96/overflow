defmodule Overflow.Search.Behaviour do
  @moduledoc """
  Behaviour for search implementations.

  Defines the contract that all search implementations must follow.
  """

  @callback search(String.t()) :: {:ok, list()} | {:error, any()}
end
