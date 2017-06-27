defmodule Blazay.Uploader.LargeFile do
  use GenServer

  alias Blazay.B2.{LargeFile, Upload}
  alias Blazay.Uploader.{
    TaskSupervisor,
    Progress
  }

  alias Blazay.Job

  def start_link(file_path, name) do
    GenServer.start_link(__MODULE__, file_path, name: name)
  end

  def init(file_path) do
    job = file_path |> Job.create
    {:ok, progress} = Progress.start_link
    {:ok, %{job: job, progress: progress}}
  end
  
  def entry(pid), do: GenServer.call(pid, :entry)
  def threads(pid), do: GenServer.call(pid, :threads)
  def upload(pid), do: GenServer.cast(pid, :upload)
  def finish(pid), do: GenServer.call(pid, :finish)
  def progress(pid), do: GenServer.call(pid, :progress)
  
  def cancel(pid) do
    cancellation = GenServer.call(pid, :cancel)
    {GenServer.stop(pid), cancellation}
  end

  def handle_cast(:upload, state) do
    Task.Supervisor.start_child(TaskSupervisor, fn -> 
      upload_stream(state.job, state.progress)
    end)
    
    {:noreply, state}
  end

  def handle_call(:progress, _from , state) do
    {:reply, Progress.get(state.progress), state}
  end
  
  def handle_call(:entry, _from, state) do
    {:reply, state.job.entry, state}
  end

  def handle_call(:threads, _from, state) do
    {:reply, state.job.threads, state}
  end

  def handle_call(:finish, _from, state) do
    sha1_array = state.job.threads.map(fn thread -> 
      thread.checksum 
    end)
    LargeFile.finish(state.file_id, sha1_array)
  end

  def handle_call(:cancel, _from, state) do
    {:ok, cancellation} = Task.Supervisor.async(TaskSupervisor, fn -> 
      LargeFile.cancel(state.file_id)
    end) |> Task.await()
    
    {:reply, cancellation, state}
  end

  defp upload_stream(job, progress) do
    job.entry.stream 
    |> Stream.with_index 
    |> Enum.map(&(create_upload_task(&1, job.threads, progress)))
    |> Task.yield_many(100_000)
    |> Stream.with_index
    |> Enum.map(&(verify_upload_task(&1, job.threads)))
  end

  defp create_upload_task({chunk, index}, threads, progress) do    
    Task.Supervisor.async(TaskSupervisor, fn ->
      thread = Enum.at(threads, index)
      url = thread.part_url.upload_url
      
      header = %{ 
        authorization: thread.part_url.authorization_token,
        x_bz_part_number: (index + 1),
        content_length: thread.content_length,
        x_bz_content_sha1: thread.checksum
      }

      # pass a stream so we can count the bytes in between
      chunk_stream = Stream.map(chunk, fn byte -> 
        # pipe the byte through progress tracker
        byte
        |> byte_size
        |> Progress.add_bytes_out(progress, index, thread)

        # return the original byte
        byte
      end)

      Upload.part(url, header, chunk_stream)
    end)
  end

  defp verify_upload_task({{_task, {:ok, result}}, index}, threads) do
    {:ok, part} = result
    thread = Enum.at(threads, index)
    if part.content_sha1 == thread.checksum,
      do: :ok, else: :error
  end
end