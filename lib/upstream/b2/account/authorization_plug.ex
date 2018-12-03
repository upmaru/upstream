defmodule Upstream.B2.Account.AuthorizationPlug do
  import Plug.Conn

  alias Upstream.B2.Account

  @spec init(any()) :: any()
  def init(options), do: options

  @spec call(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def call(conn, _opts) do
    assign(conn, :auth, Account.authorization())
  end
end
