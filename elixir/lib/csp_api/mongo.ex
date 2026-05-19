defmodule CspApi.Mongo do
  @moduledoc """
  Thin facade over `:mongodb_driver` so the rest of the app talks to a
  single name. All read/write calls in the contexts go through here.
  """

  @conn :mongo

  def conn, do: @conn

  def find(coll, filter, opts \\ []) do
    Mongo.find(@conn, coll, filter, opts)
  end

  def find_all(coll, filter, opts \\ []) do
    @conn
    |> Mongo.find(coll, filter, opts)
    |> Enum.to_list()
  end

  def find_one(coll, filter, opts \\ []) do
    Mongo.find_one(@conn, coll, filter, opts)
  end

  def find_one_and_update(coll, filter, update, opts \\ []) do
    Mongo.find_one_and_update(@conn, coll, filter, update, opts)
  end

  def insert_one(coll, doc, opts \\ []) do
    Mongo.insert_one(@conn, coll, doc, opts)
  end

  def update_one(coll, filter, update, opts \\ []) do
    Mongo.update_one(@conn, coll, filter, update, opts)
  end

  def delete_one(coll, filter, opts \\ []) do
    Mongo.delete_one(@conn, coll, filter, opts)
  end

  def count_documents(coll, filter, opts \\ []) do
    Mongo.count_documents(@conn, coll, filter, opts)
  end
end
