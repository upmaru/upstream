defmodule Upstream.Endpoint do
  import Plug.Conn

  alias Upstream.B2

  def render_json(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Poison.encode!(body))
  end

  def get_location(prefix, path) do
    {:ok, %{authorization_token: token}} = B2.Download.authorize(prefix, 3600)

    ["/" <> Upstream.config(:bucket_name), prefix, path, token]
    |> List.flatten()
    |> Enum.join("/")
  end
end
