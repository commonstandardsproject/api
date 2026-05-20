defmodule CspApi.Algolia.TestAdapter do
  @moduledoc """
  Test adapter for `CspApi.Algolia`. Records every `index/2` call in
  the process dictionary as `{index_name, document}` tuples so tests
  can assert on what would have been sent.
  """

  def index(index_name, objects) when is_list(objects) do
    # One call to index/2 = one entry. The batch of objects stays packed
    # together so tests can assert on either the batch count or the
    # individual documents.
    existing = Process.get(:algolia_indexed, [])
    Process.put(:algolia_indexed, existing ++ [{index_name, objects}])
    :ok
  end
end
