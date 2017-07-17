defmodule Blazay.Plug do
  @moduledoc """
  This is the Plug to be used in another Plug Application
  it will start the `Blazay.Router` so exposing the upload
  endpoints.
  """
  alias Blazay.Router

  def init(options) do
    options
  end

  def call(conn, opts) do
    namespace = opts[:namespace] || "blazay"
    conn = Plug.Conn.assign(conn, :namespace, namespace)
  end
end
