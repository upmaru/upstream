defmodule Blazay.Uploader.LargeFile do
  use GenServer

  alias Blazay.B2.{LargeFile, Upload}
  alias Blazay.Uploader.TaskSupervisor

  alias Blazay.Job

  def start_link(file_path) do
    GenServer.start_link(__MODULE__, file_path)
  end

  def init(file_path) do
    job = Job.create(:large_file, file_path)

    {:ok, started} = Task.Supervisor.async(TaskSupervisor, fn ->
      LargeFile.start(job.basename)
    end) |> Task.await()

    {:ok, part_url} = Task.Supervisor.async(TaskSupervisor, fn -> 
      Upload.part_url(started.file_id)
    end) |> Task.await()

    {:ok, %{job: job, b2: %{start: started, part_url: part_url}}}
  end
  
  def get(pid, :b2), do: GenServer.call(pid, :b2)
  def get(pid, :job), do: GenServer.call(pid, :job)
  
  def cancel(pid) do
    cancellation = GenServer.call(pid, :cancel)
    {GenServer.stop(pid), cancellation}
  end

  def handle_call(:b2, _from, state) do
    {:reply, state.b2, state}
  end

  def handle_call(:job, _from, state) do
    {:reply, state.job, state}
  end

  def handle_call(:cancel, _from, state) do
    {:ok, cancellation} = Task.Supervisor.async(TaskSupervisor, fn -> 
      LargeFile.cancel(state.b2.start.file_id)
    end) |> Task.await()

    {:reply, cancellation, Map.merge(state, %{cancel: cancellation})}
  end
end