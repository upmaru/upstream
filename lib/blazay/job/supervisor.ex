defmodule Blazay.Job.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      worker(Blazay.Job.LargeFile, [])
    ]

    supervise(children, strategy: :one_for_one)
  end

  def start_uploader(:large_file, file_path) do
    child_spec = supervisor(Blazay.Uploader.Supervisor, [file_path])

    __MODULE__ |> Supervisor.start_child(child_spec)
  end
end