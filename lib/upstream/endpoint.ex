defmodule Upstream.Endpoint do
  import Plug.Conn

  @spec render_json(Plug.Conn.t(), atom() | integer(), any()) :: Plug.Conn.t()
  def render_json(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end

  @spec merge_success(atom() | %{:__struct__ => atom(), optional(atom()) => any()}) :: %{
          success: true
        }
  def merge_success(struct) do
    struct
    |> Map.from_struct()
    |> Map.merge(%{success: true})
  end

  @spec merge_fail(atom() | %{:__struct__ => atom(), optional(atom()) => any()}) :: %{
          success: false
        }
  def merge_fail(struct) do
    struct
    |> Map.from_struct()
    |> Map.merge(%{success: false})
  end
end
