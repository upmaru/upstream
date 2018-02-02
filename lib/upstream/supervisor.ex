defmodule Upstream.Supervisor do
  @moduledoc """
  Supervisor for the Upstream App
  """
  use Supervisor

  alias Upstream.Uploader
  alias Upstream.B2.Account

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def stop do
    Supervisor.stop(__MODULE__, :normal)
  end

  def init(:ok) do
    children = [
      worker(Account, []),
      supervisor(Uploader, [])
    ]

    supervise(children, strategy: :one_for_one, name: __MODULE__)
  end
end
