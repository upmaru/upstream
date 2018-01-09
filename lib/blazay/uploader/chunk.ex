defmodule Upstream.Uploader.Chunk do
  @moduledoc """
  Supervisor for Uploader.File
  """
  use Supervisor

  alias Upstream.Worker

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      worker(Worker.Chunk, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  def start_uploader(job) do
    {:ok, _pid} = Supervisor.start_child(__MODULE__, [job])
    Worker.Chunk.upload(job.uid.name)
  end
end
