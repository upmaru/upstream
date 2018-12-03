defmodule Upstream.B2 do
  alias Upstream.{
    Uploader, Job
  }

  @spec upload_chunk(binary(), binary() | map()) :: {:error, any()} | {:ok, any()}
  def upload_chunk(chunk_path, params) do
    job = Job.create(chunk_path, params)
    if Job.State.errored?(job), do: Job.State.retry(job)

    start_and_register(job, fn -> start_upload(Chunk, job) end)
  end

  @spec upload_file(binary(), binary() | %{file_id: any(), index: any()}, any()) ::
          {:error, any()} | {:ok, any()}
  def upload_file(file_path, name, metadata \\ %{}) do
    job = Job.create(file_path, name, metadata)
    if Job.State.errored?(job), do: Job.State.retry(job)

    start_and_register(job, fn -> start_upload(file_worker_type(job.threads), job) end)
  end

  defp file_worker_type(1), do: StandardFile
  defp file_worker_type(_), do: LargeFile

  defp start_and_register(job, on_start) do
    if Job.State.uploading?(job) || Job.State.done?(job) do
      get_result_or_start(job, on_start)
    else
      on_start.()
    end
  end

  defp get_result_or_start(job, on_start) do
    case Job.State.get_result(job) do
      {:ok, reply} ->
        {:ok, reply}

      {:error, %{error: :no_reply}} ->
        Job.State.retry(job)
        on_start.()
    end
  end

  defp start_upload(module, job) do
    with {:ok, pid, module} <- Uploader.start_worker(module, job),
         {:ok, result} <- module.upload(pid)
    do
      {:ok, result}
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
