defmodule Blazay.CDN do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/:prefix/*path" do
    {:ok, %{authorization_token: token}} =
      Blazay.B2.Download.authorize(prefix, 3600)

    location =
      ["/" <> Blazay.config(:bucket_name), 
       prefix, path, token]
      |> List.flatten
      |> Enum.join("/")

    render_json(conn, 200, %{
      sequences: [%{
        clips: [%{
          type: "source", 
          path: location
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