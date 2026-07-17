defmodule CspApi.ID do
  @moduledoc """
  ID helpers matching `lib/securerandom.rb` in the Ruby app.
  """

  @base58_alphabet ~c"123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

  @doc "UUIDv4 with hyphens stripped and uppercased."
  def csp_uuid do
    UUID.uuid4() |> String.replace("-", "") |> String.upcase()
  end

  @doc "Base58 token used for `apiKey`."
  def base58(n \\ 16) do
    1..n
    |> Enum.map_join("", fn _ ->
      <<idx>> = :crypto.strong_rand_bytes(1)
      <<Enum.at(@base58_alphabet, rem(idx, length(@base58_alphabet)))>>
    end)
  end
end
