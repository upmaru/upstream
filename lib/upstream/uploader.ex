defmodule Upstream.Uploader do
  @moduledoc """
  Manages Supervisors for Uploaders
  """

  use DynamicSupervisor

  alias Upstream.{
    Job, Worker
  }

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link([]) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  @spec init(any()) ::
          {:ok,
           %{
             extra_arguments: [any()],
             intensity: non_neg_integer(),
             max_children: :infinity | non_neg_integer(),
             period: pos_integer(),
             strategy: :one_for_one
           }}
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec start_worker(atom() | binary(), any()) ::
          :ignore | {:error, any()} | {:ok, pid()} | {:ok, pid(), any()}
  def start_worker(worker_module, job) do
    module = Module.concat(Worker, worker_module)

    child_spec = {module, job}
    case DynamicSupervisor.start_child(__MODULE__, child_spec) do
      {:ok, pid} -> {:ok, pid, module}
      {:error, reason} -> {:error, reason}
      :ignore -> :ignore
    end
  end

  @spec upload_chunk!(binary(), binary() | %{file_id: any(), index: any()}) :: {:error, any()} | {:ok, any()}
  def upload_chunk!(chunk_path, params) do
    job = Job.create(chunk_path, params)
    if Job.State.errored?(job), do: Job.State.retry(job)

    start_and_register(job, fn -> start_upload(Chunk, job) end)
  end

  @spec upload_file!(binary(), binary() | %{file_id: any(), index: any()}, any()) :: {:error, any()} | {:ok, any()}
  def upload_file!(file_path, name, metadata \\ %{}) do
    job = Job.create(file_path, name, metadata)
    if Job.State.errored?(job), do: Job.State.retry(job)

    worker_type =
      if job.threads == 1,
        do: StandardFile,
        else: LargeFile

    start_and_register(job, fn -> start_upload(worker_type, job) end)
  end

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
    with {:ok, pid, module} <- start_worker(module, job),
         {:ok, result} <- module.upload(pid)
    do
      {:ok, result}
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
