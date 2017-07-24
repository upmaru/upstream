defmodule Blazay.Uploader.LargeFile do
  @moduledoc """
  Supervisor for Uploader.LargeFile
  """
  use Supervisor

  alias Blazay.Worker

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      worker(Worker.LargeFile, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  def start_uploader(job) do
    {:ok, _pid} = Supervisor.start_child(__MODULE__, [job])
    Worker.LargeFile.upload(job.uid.name)
  end
end
