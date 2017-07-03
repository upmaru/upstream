defmodule Blazay.Uploader.Supervisor do
  @moduledoc """
  The Supervisor for uploaders, it manages the starting and stopping
  of all the uploaders.
  """
  use Supervisor

  alias Blazay.Uploader.{
    LargeFile,
    File
  }

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

  def start_large_file(job) do
    child_spec = worker(LargeFile, [job])
    {:ok, pid} = Supervisor.start_child(__MODULE__ , child_spec)

    Registry.register(Blazay.Uploader.Registry, job.entry.name, pid)
  end

  def finish_large_file(file_path) do
    pid =  child_pid(file_path)

    pid
    |> GenServer.call(:finish)
    |> GenServer.call(:stop)

    Registry.unregister(Blazay.Uploader.Registry, file_path)
  end

  def start_file(job) do
    child_spec = worker(File, [job])
    {:ok, pid} = Supervisor.start_child(__MODULE__, child_spec)

    Registry.register(Blazay.Uploader.Registry, job.entry.name, pid)
  end

  defp child_pid(file_path) do
    [{pid, _}] = Registry.lookup(Blazay.Uploader.Registry, file_path)

    pid
  end
end
