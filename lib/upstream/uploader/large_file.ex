defmodule Upstream.Uploader.LargeFile do
  @moduledoc """
  Supervisor for Uploader.LargeFile
  """
  use Supervisor

  alias Upstream.Worker
  alias Upstream.Job

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      worker(Worker.LargeFile, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  def perform(job) do
    with {:ok, pid} <- Supervisor.start_child(__MODULE__, [job]),
         {:ok, result} <- Worker.LargeFile.upload(pid) do
      {:ok, result}
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
