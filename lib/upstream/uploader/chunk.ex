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
      worker(Worker.Chunk, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  def perform(job) do
    with {:ok, pid} <- Supervisor.start_child(__MODULE__, [job]),
         {:ok, result} <- Worker.Chunk.upload(pid) do
      {:ok, result}
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
