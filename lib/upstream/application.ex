defmodule Upstream.Application do
  @moduledoc """
  Supervisor for the Upstream App
  """
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(Upstream.B2.Account, []),
      supervisor(Upstream.Uploader, [])
    ]

    opts = [strategy: :one_for_one, name: Upstream.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
