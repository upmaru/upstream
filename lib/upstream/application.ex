defmodule Upstream.Application do
  @moduledoc """
  Supervisor for the Upstream App
  """
  use Application

  def start(_type, _args) do
    children = [
      Upstream.B2.Account,
      Upstream.Uploader,
      Upstream.Store
    ]

    opts = [strategy: :one_for_one, name: Upstream.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def prep_stop(state) do
    {:ok, _} = Upstream.Store.clear()
    state
  end
end
