defmodule Blazay.Uploader.LargeFile do
  use GenServer

  alias Blazay.B2.{LargeFile, Upload}
  alias Blazay.Uploader.TaskSupervisor

  alias Blazay.Job

  require IEx

  def start_link(file_path) do
    GenServer.start_link(__MODULE__, file_path)
  end

  def init(file_path) do
    job = file_path |> Job.create
    {:ok, job}
  end
  
  def get(pid, :entry), do: GenServer.call(pid, :entry)
  def get(pid, :threads), do: GenServer.call(pid, :threads)
  def upload(pid), do: GenServer.cast(pid, :upload)
  
  def cancel(pid) do
    cancellation = GenServer.call(pid, :cancel)
    {GenServer.stop(pid), cancellation}
  end

  def handle_cast(:upload, state) do
    state.entry.stream 
    |> Stream.with_index 
    |> Enum.map(&(create_upload_task(&1, state.threads)))
    |> Task.yield_many(100_000)
    |> Enum.with_index
    |> Enum.map(&(verify_upload_task(&1, state.threads)))
    
    {:noreply, state}
  end
  
  def handle_call(:entry, _from, state) do
    {:reply, state.entry, state}
  end

  def handle_call(:threads, _from, state) do
    {:reply, state.threads, state}
  end

  def handle_call(:cancel, _from, state) do
    {:ok, cancellation} = Task.Supervisor.async(TaskSupervisor, fn -> 
      LargeFile.cancel(state.file_id)
    end) |> Task.await()
    
    {:reply, cancellation, state}
  end

  defp create_upload_task({chunk, index}, threads) do    
    Task.Supervisor.async(TaskSupervisor, fn ->
      thread = Enum.at(threads, index)
      url = thread.part_url.upload_url
      header = %{ 
        authorization: thread.part_url.authorization_token,
        x_bz_part_number: (index + 1),
        content_length: thread.content_length,
        x_bz_content_sha1: thread.checksum
      }

      ## pass a stream so we can count the bytes in between
      ## make this better
      chunk_stream = Stream.map(chunk, fn byte -> 
        byte_size(byte)
        byte
      end)

      Upload.part(url, header, stream_chunk)
    end)
  end

  defp verify_upload_task({{_task, {:ok, result}}, index}, threads) do
    {:ok, part} = result
    thread = Enum.at(threads, index)
    if part.content_sha1 == thread.checksum,
      do: :ok, else: :error
  end
end