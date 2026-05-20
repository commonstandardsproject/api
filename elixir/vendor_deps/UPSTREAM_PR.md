# Upstream PR for mongodb_ecto

The Elixir port at `commonstandardsproject/api` pins `mongodb_ecto` to a
vendored copy in `vendor_deps/mongodb_ecto/` with a single-file patch.
This document is the PR-ready material for sending that patch upstream.

The patch itself: `vendor_deps/mongodb_ecto.patch` (apply against the
v2.1.1 tag).

## How to push it

This session's GitHub MCP is scoped to
`commonstandardsproject/api` — it can't push to `elixir-mongo`. Push
from a local clone:

```sh
git clone https://github.com/elixir-mongo/mongodb_ecto.git
cd mongodb_ecto
git checkout -b scope-pk-rename-to-top-level
git am /path/to/mongodb_ecto.patch     # or: git apply + git commit
git push origin scope-pk-rename-to-top-level
```

Then open the PR with the title and body below.

---

## PR title

```
Scope the primary-key → _id rename to the outermost document
```

## PR body

The MongoDB convention of renaming the schema's primary-key field to
`_id` is currently applied at every level of recursion. Once
`Conversions.from_ecto_pk/2` descends into a nested map (for example an
`embeds_one` sub-document), the parent schema's `pk` is still threaded
through, so any nested field named `:id` is also rewritten to `:_id`.

That means an embedded value like

```elixir
%{jurisdiction: %{id: "MD", title: "Maryland"}}
```

gets stored as

```
{ jurisdiction: { _id: "MD", title: "Maryland" } }
```

even when the embedded schema declared its own
`@primary_key {:id, :string, autogenerate: false}`. Queries that filter
on `jurisdiction.id` (the common shape for apps that put a string
identifier on a sub-document) return nothing, and the wire format
diverges from what other Mongo clients (the Ruby driver, the Node
driver, plain `mongosh` inserts) would write for the same model.

The pk → `_id` rename is only meaningful at the top of a document.
Below that, the field names are user-controlled and should be passed
through unchanged. This patch makes the recursive calls inside
`document/2` and `document/3` pass `nil` for the pk, so the rename
only fires for the outermost document.

### Repro (before this patch)

```elixir
defmodule MySet do
  use Ecto.Schema
  @primary_key {:id, :string, autogenerate: false}
  schema "my_sets" do
    field :title, :string
    embeds_one :jurisdiction, Jurisdiction
  end

  defmodule Jurisdiction do
    use Ecto.Schema
    @primary_key {:id, :string, autogenerate: false}
    embedded_schema do
      field :title, :string
    end
  end
end

%MySet{}
|> Ecto.Changeset.cast(%{id: "X", title: "t", jurisdiction: %{id: "MD", title: "Maryland"}}, [:id, :title])
|> Ecto.Changeset.cast_embed(:jurisdiction)
|> Repo.insert!()

Mongo.Ecto.command(Repo, find: "my_sets", filter: %{})
# => firstBatch with: %{"_id" => "X", "jurisdiction" => %{"_id" => "MD", ...}}
```

After the patch the nested key is `id`, not `_id`.

### Read path

`Conversions.to_ecto_pk/2` (the read path) is left as-is for now. Its
rename of nested `"_id"` → `Atom.to_string(pk)` only matters when a
sub-document actually contains an `_id` field. Mongo only auto-creates
`_id` on top-level documents, so this is rare in practice. A symmetric
read-side change can follow separately if there's appetite — happy to
add it to this PR if you'd prefer.

### Tests

The existing mongodb_ecto test suite passes against this change.
Downstream verification: the CSP API
(`commonstandardsproject/api`, vendored copy at `elixir/vendor_deps/mongodb_ecto/`)
goes from 17 broken read-side contract tests to a clean run of 34/34
once `jurisdiction.id` queries stop missing.
