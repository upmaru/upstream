defmodule Blazay.Downstream do
  import Blazay.Endpoint
  use Plug.Router

  alias Blazay.B2

  plug :match
  plug :dispatch

  get "/:prefix/*path" do
    render_json(conn, 200, %{
      sequences: [%{
        clips: [%{
          type: "source", 
          path: get_location(prefix, path)
        }]
      }]
    })
  end

  defp get_location(prefix, path) do
    {:ok, %{authorization_token: token}} =
      B2.Download.authorize(prefix, 3600)

    ["/" <> Blazay.config(:bucket_name), 
      prefix, path, token]
    |> List.flatten
    |> Enum.join("/")
  end
end