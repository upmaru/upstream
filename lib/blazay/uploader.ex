defmodule Blazay.Uploader do
  @moduledoc """
  Manages Supervisors for Uploaders
  """

  use Supervisor

  alias Blazay.Job

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

  def upload_chunk!(chunk_path, file_id, index, owner \\ nil) do
    job = Job.create(chunk_path, "#{file_id}_#{index}", owner)

    start_and_register job, fn ->
      start_uploader(:chunk, job, file_id, index)
      {:ok, :chunk, job.name}
    end
  end

  def upload!(file_path, name, owner \\ nil) do
    job = Job.create(file_path, name, owner)

    uploader = if job.threads == 1,
      do: :file, else: :large_file

    start_and_register job, fn ->
      start_uploader(uploader, job)
      {:ok, uploader, job.name}
    end
  end

  defp start_and_register(job, on_start) do
    case Registry.lookup(__MODULE__.Registry, job.name) do
      [{pid, nil}] ->
        {:error, :already_uploading, pid}
      [] -> on_start.()
    end
  end

  defp start_uploader(:chunk, job, file_id, index) do
    __MODULE__.Chunk.start_uploader(job, file_id, index)
  end

  defp start_uploader(:file, job) do
    __MODULE__.File.start_uploader(job)
  end

  defp start_uploader(:large_file, job) do
    __MODULE__.LargeFile.start_uploader(job)
  end
end
