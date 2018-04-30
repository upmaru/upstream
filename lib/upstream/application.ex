defmodule Upstream.Application do
  @moduledoc """
  Supervisor for the Upstream App
  """
  use Application

  def start(_type, _args) do
    children = [
      Upstream.B2.Account,
      Upstream.Uploader,
      {Registry, keys: :unique, name: Upstream.Registry}
    ]

    children = start_store(children)

    opts = [strategy: :one_for_one, name: Upstream.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def start_store(children) do
    if is_nil(Upstream.config(:redis_url)) do
      children
    else
      [Upstream.Store | children]
    end
  end
end
