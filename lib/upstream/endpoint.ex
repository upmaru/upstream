defmodule Upstream.Endpoint do
  import Plug.Conn

  alias Upstream.B2

  def render_json(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Poison.encode!(body))
  end
end
