defmodule Blazay.Uploader.Supervisor do
  use Supervisor

  alias Blazay.Uploader.LargeFile

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end
  
  def init(:ok) do
    children = [
      supervisor(Task.Supervisor, [[name: Blazay.Uploader.TaskSupervisor]]),
      supervisor(Registry, [:unique, Blazay.Uploader.Registry]),
    ]

    supervise(children, strategy: :one_for_one)
  end

  def start_large_file(job, name) do
    child_spec = worker(LargeFile, [job, name])
    __MODULE__ |> Supervisor.start_child(child_spec)
  end
end