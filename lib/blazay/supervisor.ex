defmodule Blazay.Supervisor do
  use Supervisor

  alias Blazay.Job
  
  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      worker(Blazay.B2.Account, []),
      worker(Redix, ["redis://localhost:6379/0", [name: :redix_blazay]])
    ]

    supervise(children, strategy: :one_for_one, name: __MODULE__)
  end

  def start_job(file_name) do
    child_spec = supervisor(Blazay.Job.Supervisor, [file_name])
    __MODULE__ |> Supervisor.start_child(child_spec)
  end
end