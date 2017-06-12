defmodule Blazay.Job.Supervisor do
  use Supervisor

  def start_link(file_path) do
    Supervisor.start_link(__MODULE__, file_path, name: __MODULE__)
  end

  def init(file_path) do
    children = [
      worker(Blazay.Job.LargeFile, [file_path])

      supervisor(Blazay.Uploader.Supervisor, [file_path])
    ]

    supervise(children, strategy: :one_for_one)
  end
end