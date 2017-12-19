defmodule Blazay.CDN do
  import Blazay.Endpoint
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
end