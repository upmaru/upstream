defmodule Blazay.Uploader.LargeFile do
  use GenServer

  alias Blazay.B2.{LargeFile, Upload}
  alias Blazay.Uploader.TaskSupervisor

  alias Blazay.Job

  def start_link(file_path) do
    GenServer.start_link(__MODULE__, file_path)
  end

  def init(file_path) do
    job = file_path |> Job.create

    {:ok, job}
  end
  
  def get(pid, :entry), do: GenServer.call(pid, :entry)
  def get(pid, :job), do: GenServer.call(pid, :job)
  
  def cancel(pid) do
    cancellation = GenServer.call(pid, :cancel)
    {GenServer.stop(pid), cancellation}
  end

  def handle_call(:entry, _from, state) do
    {:reply, state.entry, state}
  end

  def handle_call(:job, _from, state) do
    {:reply, state.job, state}
  end

  def handle_call(:cancel, _from, state) do
    {:ok, cancellation} = Task.Supervisor.async(TaskSupervisor, fn -> 
      LargeFile.cancel(state.b2.start.file_id)
    end) |> Task.await()
    
    {:reply, cancellation, state}
  end
end