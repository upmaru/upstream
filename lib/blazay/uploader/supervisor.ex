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

  def finish_large_file(file_path) do 
    pid = file_path |> child_pid

    pid
    |> GenServer.call(:finish)
    |> GenServer.call(:stop)

    Registry.unregister(Blazay.Uploader.Registry, file_path)
  end

  def start_file(job, name) do
    
  end

  defp child_pid(file_path) do
    [{pid, _}] = Registry.lookup(Blazay.Uploader.Registry, file_path)
    
    pid
  end
end
