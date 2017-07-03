defmodule Blazay.Uploader.LargeFile do
  @moduledoc """
  LargeFile Uploader handles all the interaction to upload a large file.
  """
  use GenServer

  alias Blazay.B2.LargeFile

  alias Blazay.Uploader.{
    TaskSupervisor,
    Status
  }

  alias Blazay.Job

  require Logger

  def start_link(job) do
    GenServer.start_link(__MODULE__, job)
  end

  def init(job) do
    {:ok, status} = Status.start_link

    {:ok, started} = LargeFile.start(job.name)

    threads = Enum.map(
      prepare_threads(job, started.file_id),
      &Task.await/1
    )

    {:ok, %{
      job: job,
      file_id: started.file_id,
      threads: threads,
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
      upload_stream(state.job, state.status)
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
    sha1_array = Enum.map state.threads, fn thread ->
      thread.checksum
    end

    {:ok, finished} = LargeFile.finish(state.file_id, sha1_array)

    new_state = Map.merge(state, %{current_state: :finished})

    {:reply, finished, new_state}
  end

  def handle_call(:cancel, _from, state) do
    {:ok, cancelled} = Task.await(cancel_upload(state.file_id))

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
        Task.await(cancel_upload(state.file_id))
        Logger.info "-----> Cancelled #{state.job.entry.name}"
        :shutdown
    end
  end

  defp prepare_threads(job, file_id) do
    alias __MODULE__.Thread

    for chunk <- job.stream do
      Task.Supervisor.async TaskSupervisor, fn ->
        Thread.prepare(chunk, file_id)
      end
    end
  end

  defp cancel_upload_task(file_id) do
    Task.Supervisor.async TaskSupervisor, fn ->
      LargeFile.cancel(file_id)
    end
  end

  defp upload_stream(job, status) do
    job.stream
    |> Stream.with_index
    |> Enum.map(&(create_upload_task(&1, job.threads, status)))
    |> Task.yield_many(100_000)
    |> Stream.with_index
    |> Enum.map(&(verify_upload_task(&1, job.threads)))
    |> Status.verify_and_finish(status, job.entry, job.threads)
  end

  defp create_upload_task({chunk, index}, threads, status) do
    alias Blazay.B2.Upload

    Task.Supervisor.async TaskSupervisor, fn ->
      thread = Enum.at(threads, index)
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
        |> Status.add_bytes_out(status, index, thread)

        # return the original byte
        byte
      end

      Upload.part(url, header, chunk_stream)
    end
  end

  defp verify_upload_task({{_task, {:ok, result}}, index}, threads) do
    {:ok, part} = result
    thread = Enum.at(threads, index)
    if part.content_sha1 == thread.checksum,
      do: :ok, else: :error
  end
end
