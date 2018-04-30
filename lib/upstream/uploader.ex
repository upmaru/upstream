defmodule Upstream.Uploader do
  @moduledoc """
  Manages Supervisors for Uploaders
  """

  use Supervisor

  alias Upstream.{
    Job,
    Store
  }

  def start_link(_args) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      supervisor(__MODULE__.Chunk, []),
      supervisor(__MODULE__.LargeFile, []),
      supervisor(__MODULE__.StandardFile, []),
      supervisor(Task.Supervisor, [[name: __MODULE__.TaskSupervisor]])
    ]

    supervise(children, strategy: :one_for_one)
  end

  def upload_chunk!(chunk_path, params) do
    job = Job.create(chunk_path, params)

    start_and_register job do
      start_uploader(:chunk, job)
    end
  end

  def upload_file!(file_path, name, metadata \\ %{}) do
    job = Job.create(file_path, name, metadata)

    file_type = if job.threads == 1, do: :standard, else: :large

    start_and_register job do
      start_uploader(file_type, job)
    end
  end

  defp start_and_register(job, do: block) do
    if Store.exist?(job.uid.name),
      do: {:error, :already_uploading, job.uid.name},
      else: block
  end

  defp start_uploader(:chunk, job) do
    __MODULE__.Chunk.perform(job)
  end

  defp start_uploader(:standard, job) do
    __MODULE__.StandardFile.perform(job)
  end

  defp start_uploader(:large, job) do
    __MODULE__.LargeFile.perform(job)
  end
end
