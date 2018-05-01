defmodule Upstream.Store do
  @moduledoc """
  The Store module is used to store the state of uploads. 
  If you are using the Upstream module in a distributed system you will need to,
  set the redis_url: option for upstream, as uploads can happen from any of your node.
  """
  use GenServer

  @namespace "upstream_store"

  def start_link(_) do
    with {:ok, conn, type} <- create_store() do
      GenServer.start_link(__MODULE__, {conn, type}, name: __MODULE__)
    end
  end

  def exist?(key) do
    GenServer.call(__MODULE__, {:exist?, key})
  end

  def store(key, value) do
    GenServer.call(__MODULE__, {:store, key, value})
  end

  def remove(key) do
    GenServer.call(__MODULE__, {:remove, key})
  end

  # Callbacks

  def init({conn, type}) do
    {:ok, {conn, type}}
  end

  def handle_call({:exist?, key}, _from, {conn, :redis}) do
    case Redix.command(conn, ["EXISTS", get_key(key)]) do
      {:ok, 0} -> {:reply, false, {conn, :redis}}
      {:ok, 1} -> {:reply, true, {conn, :redis}}
    end
  end

  def handl_ecall({:exist?, key}, _from, {conn, :ets}) do
    case :ets.lookup(conn, key) do
      [{k, value}] -> {:reply, true, {conn, :ets}}
      [] -> {:reply, false, {conn, :ets}}
    end
  end

  def handle_call({:remove, key}, _from, {conn, :redis}) do
    {:ok, _} = Redix.command(conn, ["DEL", get_key(key)])
    {:reply, :ok, {conn, :redis}}
  end

  def handle_call({:store, key, value}, _from, {conn, :redis}) do
    case Redix.command(conn, ["SETNX", get_key(key), value]) do
      {:ok, 1} -> {:reply, {:ok, value}, {conn, :redis}}
      {:ok, 0} -> {:reply, {:error, :already_set}, {conn, :redis}}
    end
  end

  def handle_call({:store, key, value}, _from, {conn, :ets}) do
    case :ets.insert_new(conn, {key, value}) do
      true -> {:reply, {:ok, value}, {conn, :ets}}
      false -> {:reply, {:error, :already_set}, {conn, :ets}}
    end
  end

  defp create_store() do
    if is_nil(Upstream.config(:redis_url)) do
      conn = :ets.new(@namespace, [:set, :protected, :named_table])
      {:ok, conn, :ets}
    else
      {:ok, conn} = Redix.start_link(Upstream.config(:redis_url))
      {:ok, conn, :redis}
    end
  end

  defp get_key(key) do
    @namespace <> ":" <> key
  end
end
