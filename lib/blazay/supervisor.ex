defmodule Blazay.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      worker(Blazay.Account, []),
      worker(Redix, ["redis://localhost:6379/0", [name: :redix_blazay]])
    ]

    supervise(children, strategy: :one_for_one)
  end
end