defmodule Upstream.Uploader do
  @moduledoc """
  Manages Supervisors for Uploaders
  """

  use DynamicSupervisor

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link([]) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  @spec init(any()) ::
          {:ok,
           %{
             extra_arguments: [any()],
             intensity: non_neg_integer(),
             max_children: :infinity | non_neg_integer(),
             period: pos_integer(),
             strategy: :one_for_one
           }}
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec start_worker(atom() | binary(), any()) :: :ignore | {:error, any()} | {:ok, pid()} | {:ok, pid(), any()}
  def start_worker(worker_module, job) do
    module = Module.concat(Worker, worker_module)

    child_spec = {module, job}
    case DynamicSupervisor.start_child(__MODULE__, child_spec) do
      {:ok, pid} -> {:ok, pid, module}
      {:error, reason} -> {:error, reason}
      :ignore -> :ignore
    end
  end
end
