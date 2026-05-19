defmodule CspApi.ID do
  @moduledoc """
  Identifier helpers — equivalent to `SecureRandom.csp_uuid` and
  `SecureRandom.base58` from the Ruby app.
  """

  @base58_alphabet ~c"123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

  @doc """
  Random 32-character uppercase hex string, e.g.
  `"49FCDFBD2CF04033A9C347BFA0584DF0"`. Matches the Ruby app's
  `SecureRandom.csp_uuid` output (a UUIDv4 with hyphens stripped and
  uppercased).
  """
  def csp_uuid do
    <<a::32, b::16, _c1::4, c::12, _d1::2, d::62>> = :crypto.strong_rand_bytes(16)
    bin = <<a::32, b::16, 4::4, c::12, 2::2, d::62>>
    bin |> Base.encode16(case: :upper)
  end

  @doc "Base58 token used for the `apiKey` field on users."
  def base58(n \\ 16) do
    alphabet = @base58_alphabet
    size = length(alphabet)

    1..n
    |> Enum.map_join("", fn _ ->
      <<idx>> = :crypto.strong_rand_bytes(1)
      <<Enum.at(alphabet, rem(idx, size))>>
    end)
  end
end
