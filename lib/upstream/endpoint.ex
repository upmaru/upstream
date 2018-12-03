defmodule Upstream.Endpoint do
  import Plug.Conn

  @spec render_json(Plug.Conn.t(), atom() | integer(), any()) :: Plug.Conn.t()
  def render_json(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end
end
