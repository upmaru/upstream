defmodule Blazay.Utility do
  @moduledoc """
  Utilities for accessing the blazay upload system
  """
  alias Blazay.{
    Uploader,
    Job,
    B2
  }

  def upload!(file_path) do
    job = Job.create(file_path)

    uploader = if job.threads == 1, do: :file, else: :large_file

    case Registry.lookup(Uploader.Registry, job.name) do
      [{pid, nil}] ->
        {:error, :already_uploading, pid}
      [] ->
        Uploader.start_uploader(uploader, job)
        {:ok, uploader, job.name}
    end
  end

  def cancel_unfinished_large_files do
    {:ok, unfinished} = B2.LargeFile.unfinished

    tasks = Enum.map(unfinished.files, fn file ->
      Task.async(fn ->
        B2.LargeFile.cancel(file["fileId"])
      end)
    end)

    results = Task.yield_many(tasks, 10_000)
    {:ok, results}
  end
end
