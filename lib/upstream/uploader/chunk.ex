defmodule Upstream.Uploader.Chunk do
  @moduledoc """
  Supervisor for Uploader.File
  """
  use Supervisor

  alias Upstream.Worker

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  @spec init(any()) :: {:ok, {{any(), any(), any()}, any()}}
  def init(_) do
    children = [
      worker(Worker.Chunk, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  @spec perform(any(), any()) :: {:error, any()} | {:ok, any()}
  def perform(auth, job) do
    with {:ok, pid} <- Supervisor.start_child(__MODULE__, [{auth, job}]),
         {:ok, result} <- Worker.Chunk.upload(pid) do
      {:ok, result}
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
