defmodule Blazay.CDN do
  use Plug.Router

  plug :match
  plug :dispatch

  require IEx

  get "/nimbus/:prefix/*path" do
    {:ok, %{authorization_token: token}} =
      Blazay.B2.Download.authorize(prefix, 3600)

    location =
      [token, Blazay.config(:bucket_name), 
       prefix, List.flatten(path)]

    render_json(conn, 200, %{
      id: authorization.authorization_token,
      sequences: [%{
        clips: [%{
          type: "source", 
          path: Enum.join(location, "/")
        }]
      }]
    })
  end

  defp render_json(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Poison.encode!(body))
  end
end