defmodule CspApi.Hierarchy do
  @moduledoc """
  Walks a flat collection of standards and adds `ancestorIds` and
  `parentId` based on `position` and `depth`. Port of
  `lib/standard_hierarchy.rb` in the Ruby app.

  Standards are stored ordered by `position` (descending) and ancestors are
  inferred by walking the list and tracking the lowest-depth standard we've
  seen at each step.
  """

  @doc """
  Takes a map of `id => standard_map` and returns the same map with
  `ancestorIds` and `parentId` populated on every standard.

  Falls back to `%{}` when given `nil`.
  """
  def add_ancestor_ids(nil), do: %{}
  def add_ancestor_ids(standards) when map_size(standards) == 0, do: %{}

  def add_ancestor_ids(standards) when is_map(standards) do
    ordered =
      standards
      |> Map.values()
      |> Enum.sort_by(&position/1, :desc)

    ordered
    |> Enum.with_index()
    |> Enum.map(fn {standard, i} ->
      ancestors = find_ancestors(ordered, standard, i)
      depth = depth(standard)
      parent = Enum.find(ancestors, fn a -> depth(a) == depth - 1 end)

      standard
      |> Map.put("ancestorIds", Enum.map(ancestors, & &1["id"]))
      |> Map.put("parentId", parent && parent["id"])
    end)
    |> Map.new(fn s -> {s["id"], s} end)
  end

  defp find_ancestors(_all, standard, _i) when is_nil(standard), do: []

  defp find_ancestors(all, standard, i) do
    case depth(standard) do
      0 -> []
      nil -> []
      _ -> walk_ancestors(Enum.drop(all, i + 1), standard)
    end
  end

  # Walks the rest of the (descending-position) list collecting the
  # lowest-depth ancestor we've crossed at each step, stopping at the first
  # root.
  #
  # Ruby quirk preserved: when the standard is the last element in the
  # ordered list (nothing after it), the rest is `[]` and we return `[]`.
  # That means a non-root leaf at the tail of the position-desc list
  # gets `ancestorIds: []` — even though semantically it has ancestors
  # somewhere in the set. The Ruby implementation in
  # `lib/standard_hierarchy.rb` does the same thing because it iterates
  # `each_with_index` and slices `all[(idx + 1)..]`, which returns `[]`
  # at the tail. See CONVERSION_NOTES.md.
  defp walk_ancestors(rest, standard) do
    Enum.reduce_while(rest, {[], standard}, fn ss, {acc, last} ->
      case depth(ss) do
        d when d == 0 or is_nil(d) -> {:halt, {[ss | acc], ss}}
        d ->
          if d < depth(last) do
            {:cont, {[ss | acc], ss}}
          else
            {:cont, {acc, last}}
          end
      end
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  defp position(s), do: s["position"] || 0
  defp depth(s), do: s["depth"]
end
