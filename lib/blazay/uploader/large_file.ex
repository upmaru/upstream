defmodule Blazay.Uploader.LargeFile do
  @moduledoc """
  LargeFile Uploader handles all the interaction to upload a large file.
  """
  use GenServer
  require Logger
  alias Blazay.Uploader

  alias Blazay.B2.{
    LargeFile,
    Upload
  }

  alias Uploader.{
    TaskSupervisor,
    Supervisor,
    Status
  }

  alias __MODULE__.Thread

  def start_link(job) do
    GenServer.start_link(__MODULE__, job)
  end

  def init(job) do
    {:ok, status} = Status.start_link

    {:ok, started} = LargeFile.start(job.name)

    {:ok, %{
      job: job,
      file_id: started.file_id,
      status: status,
      current_state: :started
    }}
  end

  def upload(pid), do: GenServer.cast(pid, :upload)
  def cancel(pid) do
    cancellation = GenServer.call(pid, :cancel)
    {:ok, cancellation}
  end

  def stop(pid), do: GenServer.call(pid, :stop)
  def finish(pid), do: GenServer.call(pid, :finish)

  def job(pid), do: GenServer.call(pid, :job)
  def threads(pid), do: GenServer.call(pid, :threads)
  def progress(pid), do: GenServer.call(pid, :progress)

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

  def handle_call(:threads, _from, state) do
    {:reply, state.threads, state}
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
    case state.current_state do
      :uploading ->
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
    Status.stop(state.status)
    Logger.info "-----> Shutting down #{state.job.name}"
    reason
  end

  defp cancel_upload_task(file_id) do
    Task.Supervisor.async TaskSupervisor, fn ->
      LargeFile.cancel(file_id)
    end
  end

  defp upload_stream(state) do
    task = Task.Supervisor.async_stream(
      TaskSupervisor,
      Stream.with_index(state.job.stream),
      &upload_chunk(&1, state.file_id, state.status),
      max_concurrency: Blazay.concurrency,
      timeout: :infinity
    )

    Enum.each(task, &Status.add_uploaded(&1, state.status))
    Logger.info "-----> #{Status.uploaded_count(state.status)} part(s) uploaded"

    if Status.upload_complete?(state.status) do
      Supervisor.finish_large_file(state.job.name)
      Supervisor.stop_child(state.job.name)
    end
  end

  defp upload_chunk({chunk, index}, file_id, status) do
    thread = Thread.prepare(file_id, chunk)
    url = thread.part_url.upload_url

    header = %{
      authorization: thread.part_url.authorization_token,
      x_bz_part_number: (index + 1),
      content_length: thread.content_length,
      x_bz_content_sha1: thread.checksum
    }

    # pass a stream so we can count the bytes in between
    chunk_stream = Stream.map chunk, fn byte ->
      # pipe the byte through progress tracker
      byte
      |> byte_size
      |> Status.add_bytes_out(status, thread)

      # return the original byte
      byte
    end

    {:ok, _part} = Upload.part(url, header, chunk_stream)

    {index, thread.checksum}
  end
end
