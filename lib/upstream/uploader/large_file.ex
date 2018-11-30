defmodule Upstream.Uploader.LargeFile do
  @moduledoc """
  Supervisor for Uploader.LargeFile
  """
  use DynamicSupervisor

  alias Upstream.Worker

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @spec start_child() :: :ignore | {:error, any()} | {:ok, pid()} | {:ok, pid(), any()}
  def start_child do
    DynamicSupervisor.start_child(__MODULE__, {Worker.LargeFile, restart: :transient})
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
  def init(args) do
    DynamicSupervisor.init(strategy: :one_for_one, extra_arguments: [args])
  end
end
