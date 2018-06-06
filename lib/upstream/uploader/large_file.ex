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
    with {:ok, _value} <- Job.start(job),
         {:ok, _pid} <- Supervisor.start_child(__MODULE__, [job]),
         {:ok, result} <- Worker.LargeFile.upload(job.uid.name) do
      {:ok, result}
    else
      {:error, {reason, _}} -> {:error, %{error: reason}}
      {:error, reason} -> {:error, reason}
    end
  end
end
