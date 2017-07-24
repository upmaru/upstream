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

    case namespace do
      "" ->
        Router.call(conn, Router.init(opts))
      _ ->
        namespace(conn, opts, namespace)
    end
  end

  def namespace(%Plug.Conn{path_info: [ns | path]} = conn, opts, ns) do
    Router.call(%Plug.Conn{conn | path_info: path}, Router.init(opts))
  end
  def namespace(conn, _opts, _ns), do: conn
end
