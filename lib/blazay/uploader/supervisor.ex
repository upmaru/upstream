defmodule Blazay.Uploader.Supervisor do
  @moduledoc """
  The Supervisor for uploaders, it manages the life cycle
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

  def start_job(job) do
    {:ok, pid} = Supervisor.start_child(__MODULE__ , child_spec(job))

    Registry.register(Blazay.Uploader.Registry, job.name, pid)

    job.name
  end

  def cancel_large_file(file_path) do
    file_path
    |> child_pid
    |> GenServer.call(:cancel)
  end

  def finish_large_file(file_path) do
    file_path
    |> child_pid
    |> GenServer.call(:finish)
  end

  def stop_child(file_path) do
    file_path
    |> child_pid
    |> GenServer.call(:stop)

    Registry.unregister(Blazay.Uploader.Registry, file_path)
  end

  def upload(file_path) do
    file_path
    |> child_pid
    |> GenServer.cast(:upload)
  end

  defp child_spec(job) do
    if job.threads == 1 do
      worker(File, [job], restart: :transient)
    else
      worker(LargeFile, [job], restart: :transient)
    end
  end

  defp child_pid(file_path) do
    [{_, pid}] = Registry.lookup(Blazay.Uploader.Registry, file_path)

    pid
  end
end
