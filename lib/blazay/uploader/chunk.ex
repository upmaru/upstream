defmodule Blazay.Uploader.Chunk do
  @moduledoc """
  Supervisor for Uploader.File
  """
  use Supervisor

  alias Blazay.Worker

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      worker(Worker.Chunk, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  def start_uploader(job, file_id, index) do
    {:ok, _pid} = Supervisor.start_child(__MODULE__, [job, file_id, index])
    Worker.Chunk.upload(job.name)
  end
end
