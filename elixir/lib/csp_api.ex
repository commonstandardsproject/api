defmodule CspApi do
  @moduledoc """
  CSP API — Phoenix port of the Ruby Grape application that serves the
  Common Standards Project data.

  The data still lives in MongoDB. We talk to it through `:mongodb_driver`
  rather than Ecto's SQL adapter, since the document shapes (notably the
  nested `standards` map inside a standard set) map naturally to BSON.

  See `lib/csp_api/mongo.ex` for the wrapper.
  """
end
