defmodule Blazay.Worker.LargeFile do
  @moduledoc """
  LargeFile Uploader handles all the interaction to upload a large file.
  """
  use GenServer
  require Logger
  alias Blazay.{
    Uploader,
    Worker
  }

  alias Uploader.TaskSupervisor

  alias Blazay.B2.{
    LargeFile,
    Upload
  }

  alias Worker.{
    Flow,
    Status,
    Checksum
  }

  # Client API

  def start_link(job) do
    GenServer.start_link(__MODULE__, job, name: via_tuple(job.name))
  end

  def upload(job_name) do
    GenServer.cast(via_tuple(job_name), :upload)
  end

  def cancel(job_name) do
    cancellation = GenServer.call(via_tuple(job_name), :cancel)
    GenServer.call(via_tuple(job_name), :stop)
    {:ok, cancellation}
  end

  def stop(job_name) do
    GenServer.call(via_tuple(job_name), :stop)
  end

  def finish(job_name) do
    GenServer.call(via_tuple(job_name), :finish)
  end

  def job(pid) when is_pid(pid), do: GenServer.call(pid, :job)
  def job(job_name) when is_binary(job_name) do
    GenServer.call(via_tuple(job_name), :job)
  end

  def progress(job_name) do
    GenServer.call(via_tuple(job_name), :progress)
  end

  # Server Callbacks

  def init(job) do
    {:ok, status} = Status.start_link

    {:ok, started} = LargeFile.start(job.name)

    temp_directory = Path.join(["tmp", started.file_id])

    {File.mkdir_p!(temp_directory), %{
      job: job,
      file_id: started.file_id,
      temp_directory: temp_directory,
      status: status,
      current_state: :started
    }}
  end

  def handle_cast(:upload, state) do
    Task.Supervisor.start_child TaskSupervisor, fn ->
      upload_stream(state)
    end

    new_state = Map.merge(state, %{current_state: :uploading})

    {:noreply, new_state}
  end

  def handle_call(:progress, _from , state) do
    total_bytes = state.job.stat.size
    transferred_bytes = Status.bytes_transferred(state.status)

    percent_transferred =
      Float.round(((transferred_bytes / total_bytes) * 100), 2)

    {:reply, percent_transferred, state}
  end

  def handle_call(:job, _from, state) do
    {:reply, state.job, state}
  end

  def handle_call(:finish, _from, state) do
    sha1_array = Status.get_uploaded_sha1(state.status)

    {:ok, finished} = LargeFile.finish(state.file_id, sha1_array)

    new_state = Map.merge(state, %{current_state: :finished})

    {:reply, finished, new_state}
  end

  def handle_call(:cancel, _from, state) do
    {:ok, cancelled} = Task.await(cancel_upload_task(state.file_id))
    new_state = Map.merge(state, %{current_state: :cancelled})

    {:reply, cancelled, new_state}
  end

  def handle_call(:stop, _from, state) do
    Status.stop(state.status)

    case state.current_state do
      the_state when the_state in [:started, :uploading] ->
        Logger.info "-----> Cancelling #{state.job.name}"
        Task.await(cancel_upload_task(state.file_id))
        {:stop, :shutdown, state}
      :finished ->
        Logger.info "-----> #{state.job.name} #{Atom.to_string(state.current_state)}"
        {:stop, :shutdown, state}
      :cancelled ->
        Logger.info "-----> Cancelled #{state.job.name}"
        {:stop, :shutdown, state}
    end
  end

  def terminate(reason, state) do
    File.rmdir(state.temp_directory)
    Logger.info "-----> Shutting down #{state.job.name}"
    reason
  end

  # Private Functions

  defp via_tuple(job_name) do
    {:via, Registry, {Blazay.Uploader.Registry, job_name}}
  end

  defp cancel_upload_task(file_id) do
    Task.Supervisor.async TaskSupervisor, fn ->
      LargeFile.cancel(file_id)
    end
  end

  defp upload_stream(state) do
    stream = Task.Supervisor.async_stream(
      TaskSupervisor,
      chunk_streams(state.job.stream, state.temp_directory),
      &upload_chunk(&1, state.file_id, state.job, state.status),
      max_concurrency: Blazay.concurrency,
      timeout: :infinity
    )

    Stream.run(stream)

    Logger.info "-----> #{Status.uploaded_count(state.status)} part(s) uploaded"

    if Status.upload_complete?(state.status) do
      __MODULE__.finish(state.job.name)
      __MODULE__.stop(state.job.name)
    end
  end

  defp chunk_streams(stream, temp_directory) do
    stream
    |> Stream.with_index
    |> Stream.map(fn {chunk, index} ->
      path = Path.join([temp_directory, "#{index}"])
      {Enum.into(chunk, File.stream!(path, [], 2048)), index}
    end)
  end

  defp upload_chunk({chunked_stream, index}, file_id, job, status) do
    {:ok, checksum} = Checksum.start_link
    {:ok, part_url} = Upload.part_url(file_id)

    content_length = if job.threads == (index + 1),
      do: job.last_content_length, else: job.content_length

    url = part_url.upload_url

    header = %{
      authorization: part_url.authorization_token,
      x_bz_part_number: (index + 1),
      content_length: content_length + 40,
      x_bz_content_sha1: "hex_digits_at_end"
    }

    body = Flow.generate(
      chunked_stream, index, checksum, status
    )

    case Upload.part(url, header, body) do
      {:ok, part} ->
        Checksum.stop(checksum)
        Status.add_uploaded({index, part.content_sha1}, status)
        File.rm!(chunked_stream.path)
      {:error, _} ->
        Logger.info "-----> Error #{job.name} chunk: #{index}"
    end
  end
end
