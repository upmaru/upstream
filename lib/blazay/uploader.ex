defmodule Blazay.Uploader do
  @moduledoc """
  Manages Supervisors for Uploaders
  """

  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      supervisor(__MODULE__.LargeFile, []),
      supervisor(__MODULE__.File, []),

      supervisor(Task.Supervisor, [[name: __MODULE__.TaskSupervisor]]),
      supervisor(Registry, [:unique, __MODULE__.Registry])
    ]

    supervise(children, strategy: :one_for_one)
  end

  def start_uploader(:file, job) do
    __MODULE__.File.start_uploader(job)
  end

  def start_uploader(:large_file, job) do
    __MODULE__.LargeFile.start_uploader(job)
  end
end
