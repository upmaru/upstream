defmodule Upstream.Worker.LargeFile do
  @moduledoc """
  LargeFile Uploader handles all the interaction to upload a large file.
  """

  use Upstream.Worker.Base

  alias __MODULE__.Status

  alias Upstream.B2.LargeFile
  alias Upstream.Worker.Chunk

  @concurrency Application.get_env(:upstream, Upstream)[:concurrency] || 2

  # Callbacks

  @impl true
  @spec task(%{
          file_id: any(),
          job: Upstream.Job.t(),
          status: atom() | pid() | {atom(), any()} | {:via, atom(), any()},
          stream: any()
        }) ::
          {:error, %{:__struct__ => atom(), optional(atom()) => any()}}
          | {:ok, %{:__struct__ => atom(), optional(atom()) => any()}}
  def task(%{job: job} = state) do
    stream =
      Task.Supervisor.async_stream(
        Upstream.TaskSupervisor,
        chunk_streams(state),
        &upload_chunk(&1, state),
        max_concurrency: @concurrency,
        timeout: 100_000_000
      )

    Stream.run(stream)

    Logger.info("[Upstream] #{Status.uploaded_count(state.status)} part(s) uploaded")
    sha1_array = Status.get_uploaded_sha1(state.status)
    LargeFile.finish(job.authorization, state.file_id, sha1_array)
  end

  defp handle_setup(%{job: job} = state) do
    {:ok, status} = Status.start_link()

    {:ok, started} = LargeFile.start(job.authorization, job.uid.name, job.metadata)

    temp_directory = Path.join(["tmp", started.file_id])
    :ok = File.mkdir_p!(temp_directory)

    Map.merge(state, %{
      file_id: started.file_id,
      temp_directory: temp_directory,
      status: status
    })
  end

  defp handle_stop(%{job: job} = state) do
    if state.current_state in [:started, :uploading],
      do: LargeFile.cancel(job.authorization, state.file_id)

    File.rmdir(state.temp_directory)
    Status.stop(state.status)

    {:ok, state.current_state}
  end

  # Private Functions

  defp chunk_streams(job) do
    job.stream
    |> Stream.with_index()
    |> Stream.map(fn {chunk, index} ->
      path = Path.join([job.temp_directory, "#{index}"])
      {Enum.into(chunk, File.stream!(path, [], 2048)), index}
    end)
  end

  defp upload_chunk(
         {chunked_stream, index},
         %{file_id: file_id, job: job, status: status} = _state
       ) do
    content_length =
      if job.threads == index + 1,
        do: job.last_content_length,
        else: job.content_length

    chunk_state = %{
      auth: job.auth,
      stream: chunked_stream,
      content_length: content_length,
      uid: %{index: index, file_id: file_id}
    }

    case Chunk.task(chunk_state) do
      {:ok, part} ->
        Status.add_uploaded({index, part.content_sha1}, status)
        File.rm!(chunked_stream.path)

      {:error, _} ->
        Logger.info("[Upstream] Error #{job.uid.name} chunk: #{index}")
    end
  end
end
