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
    {:reply, Status.get(state.status), state}
  end

  def handle_call(:job, _from, state) do
    {:reply, state.job, state}
  end

  def handle_call(:threads, _from, state) do
    {:reply, state.threads, state}
  end

  def handle_call(:finish, _from, state) do
    sha1_array = Status.get_sha1_array(state.status)

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
      :finished -> {:stop, :normal, state}
      :cancelled -> {:stop, :normal, state}
      _ -> {:stop, :shutdown, state}
    end
  end

  def terminate(reason, state) do
    case reason do
      :normal ->
        Logger.info "-----> #{state.job.entry.name} #{Atom.to_string(state.current_state)}"
        :normal
      :shutdown ->
        Logger.info "-----> Cancelling #{state.job.entry.name}"
        Task.await(cancel_upload_task(state.file_id))
        Logger.info "-----> Cancelled #{state.job.entry.name}"
        :shutdown
    end
  end

  defp upload_stream(state) do
    task = Task.Supervisor.async_stream(
      TaskSupervisor,
      Stream.with_index(state.job.stream),
      &concurrently_upload(&1, state.file_id, state.status),
      max_concurrency: Blazay.concurrency,
      timeout: :infinity
    )

    task
    |> Stream.map(&verify_thread(&1))
    |> verify_and_finish(state.status, state.job)
  end

  defp cancel_upload_task(file_id) do
    Task.Supervisor.async TaskSupervisor, fn ->
      LargeFile.cancel(file_id)
    end
  end

  defp concurrently_upload({chunk, index}, file_id, status) do
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

    {:ok, part} = Upload.part(url, header, chunk_stream)

    {thread, part}
  end

  defp verify_thread({:ok, {thread, part}}) do
    if part.content_sha1 == thread.checksum,
      do: {:ok, thread.checksum}, else: {:error, thread.checksum}
  end

  defp verify_and_finish(results, status, job) do
    counted = Enum.reduce results, %{}, fn({result, _checksum}, acc) ->
      Map.update(acc, result, 1, &(&1 + 1))
    end

    Logger.info "-----> #{counted.ok} part(s) uploaded"

    if counted.ok == Status.thread_count(status) do
      Supervisor.finish_large_file(job.name)
      Supervisor.stop_child(job.name)
    end
  end
end
