defmodule Blazay.Uploader.File do
  @moduledoc """
  Supervisor for Uploader.File
  """
  use Supervisor

  alias Blazay.Uploader.Worker

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      worker(Worker.File, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  def start_uploader(job) do
    Supervisor.start_child(__MODULE__, [job])
  end
end
