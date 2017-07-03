defmodule Blazay.Uploader.LargeFile do
  @moduledoc """
  LargeFile Uploader handles all the interaction to upload a large file.
  """
  use GenServer

  alias Blazay.B2.{LargeFile, Upload}
  alias Blazay.Uploader.{
    TaskSupervisor,
    Status
  }

  alias Blazay.Job

  def start_link(job) do
    GenServer.start_link(__MODULE__, job)
  end

  def init(job) do
    {:ok, status} = Status.start_link
    {:ok, %{job: job, status: status}}
  end

  def stop(pid), do: GenServer.call(pid, :stop)
  def entry(pid), do: GenServer.call(pid, :entry)
  def threads(pid), do: GenServer.call(pid, :threads)
  def upload(pid), do: GenServer.cast(pid, :upload)
  def progress(pid), do: GenServer.call(pid, :progress)

  def cancel(pid) do
    cancellation = GenServer.call(pid, :cancel)
    {GenServer.stop(pid), cancellation}
  end

  def finish(pid) do
    finished = GenServer.call(pid, :finish)
    {:ok, finished}
  end

  def handle_cast(:upload, state) do
    Task.Supervisor.start_child TaskSupervisor, fn ->
      upload_stream(state.job, state.status)
    end

    {:noreply, state}
  end

  def handle_call(:stop, _from, state) do
    Status.stop(state.status)
    {:stop, :normal, state}
  end

  def handle_call(:progress, _from , state) do
    {:reply, Status.get(state.status), state}
  end

  def handle_call(:entry, _from, state) do
    {:reply, state.job.entry, state}
  end

  def handle_call(:threads, _from, state) do
    {:reply, state.job.threads, state}
  end

  def handle_call(:finish, _from, state) do
    sha1_array = Enum.map state.job.threads, fn thread ->
      thread.checksum
    end

    {:ok, finished} = LargeFile.finish(state.job.file_id, sha1_array)
    {:reply, finished, state}
  end

  def handle_call(:cancel, _from, state) do
    task = Task.Supervisor.async TaskSupervisor, fn ->
      LargeFile.cancel(state.file_id)
    end

    {:ok, cancellation} = Task.await(task)

    {:reply, cancellation, state}
  end

  def terminate(reason, state) do
    IO.puts "#{state.job.entry.name} Uploaded!"
    :ok
  end

  defp upload_stream(job, status) do
    job.entry.stream
    |> Stream.with_index
    |> Enum.map(&(create_upload_task(&1, job.threads, status)))
    |> Task.yield_many(100_000)
    |> Stream.with_index
    |> Enum.map(&(verify_upload_task(&1, job.threads)))
    |> Status.verify_and_finish(status, job.entry, job.threads)
  end

  defp create_upload_task({chunk, index}, threads, status) do
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
