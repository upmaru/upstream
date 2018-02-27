defmodule Upstream.Vod do
  @moduledoc """
  Endpoint for Nginx Vod Module
  """
  import Upstream.Endpoint

  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/:prefix/*path" do
    render_json(conn, 200, %{
      sequences: [
        %{
          clips: [
            %{
              type: "source",
              path: get_location(prefix, path)
            }
          ]
        }
      ]
    })
  end
end
