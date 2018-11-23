defmodule Upstream.Application do
  @moduledoc """
  Supervisor for the Upstream App
  """
  use Application

  @spec start(any(), any()) :: {:error, any()} | {:ok, pid()}
  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: Upstream.TaskSupervisor},
      Upstream.B2.Account,
      Upstream.Uploader,
      Upstream.Store,
      Upstream.Scheduler
    ]

    opts = [strategy: :one_for_one, name: Upstream.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
