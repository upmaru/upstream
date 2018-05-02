defmodule Upstream.Store do
  @moduledoc """
  The Store module is used to store the state of uploads. 
  If you are using the Upstream module in a distributed system you will need to,
  set the redis_url: option for upstream, as uploads can happen from any of your node.
  """
  use GenServer
  alias Upstream.Store.Redis

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def exist?(key) do
    GenServer.call(__MODULE__, {:exist?, key})
  end

  def add_member(key, value) do
    GenServer.call(__MODULE__, {:add_member, key, value})
  end

  def is_member?(key, value) do
    GenServer.call(__MODULE__, {:is_member?, key, value})
  end

  def remove_member(key, value) do
    GetServer.call(__MODULE__, {:remove_member, key, value})
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def set(key, value) do
    GenServer.call(__MODULE__, {:set, key, value})
  end

  def remove(key) do
    GenServer.call(__MODULE__, {:remove, key})
  end

  # Callbacks

  def init(:ok) do
    with {:ok, conn, type} <- create_store() do
      {:ok, {conn, type}}
    end
  end

  def handle_call({:exist?, key}, _from, {conn, :ets}) do
    case :ets.lookup(conn, key) do
      [{_k, _value}] -> {:reply, true, {conn, :ets}}
      [] -> {:reply, false, {conn, :ets}}
    end
  end

  def handle_call({:get, key}, _from, {conn, :ets}) do
    case :ets.lookup(conn, key) do
      [{_k, value}] -> {:reply, {:ok, value}, {conn, :ets}}
      [] -> {:reply, {:ok, nil}, {conn, :ets}}
    end
  end

  def handle_call({:remove, key}, _from, {conn, :ets}) do
    :ets.delete(conn, key)
    {:reply, :ok, {conn, :redis}}
  end

  def handle_call({:set, key, value}, _from, {conn, :ets}) do
    case :ets.insert_new(conn, {key, value}) do
      true -> {:reply, {:ok, value}, {conn, :ets}}
      false -> {:reply, {:error, :already_set}, {conn, :ets}}
    end
  end

  def handle_call({:add_member, key, value}, _from, {conn, :ets}) do
    case :ets.lookup(conn, key) do
      [{_k, existing}] ->
        :ets.insert(conn, {key, [value | existing]})
        {:reply, {:ok, value}, {conn, :ets}}
      [] ->
        :ets.insert_new(conn, {key, [value]})
        {:reply, {:ok, value}, {conn, :ets}}
    end
  end

  def handle_call({:is_member?, key, value}, _from, {conn, :ets}) do
    case :ets.lookup(conn, key) do
      [{_k, existing}] ->
        {:reply, Enum.member?(existing, value), {conn, :ets}}
      [] ->
        {:reply, false, {conn, :ets}}
    end
  end

  def handle_call(:remove_member, key, value}, _from, {conn, :ets}) do
    case :ets.lookup(conn, key) do
      [{_k, existing}] ->
        :ets.insert(conn, {key, Enum.reject(existing, fn v -> v == value end)})
        {:reply, :ok, {conn, :ets}}
      [] ->
        {:reply, :error, {conn, :ets}}
    end
  end

  def handle_call({:exist?, key}, _from, {conn, :redis}) do
    case Redix.command(conn, ["EXISTS", Redis.namespace(key)]) do
      {:ok, 0} -> {:reply, false, {conn, :redis}}
      {:ok, 1} -> {:reply, true, {conn, :redis}}
    end
  end

  def handle_call({:is_member?, key, value}, _from, {conn, :redis}) do
    case Redix.command(conn, ["SISMEMBER", Redis.namespace(key), value]) do
      {:ok, 1} -> {:reply, true, {conn, :redis}}
      {:ok, 0} -> {:reply, false, {conn, :redis}}
    end
  end

  def handle_call({:add_member, key, value}, _from, {conn, :redis}) do
    case Redix.command(conn, ["SADD", Redis.namespace(key), value]) do
      {:ok, 1} -> {:reply, {:ok, value}, {conn, :redis}}
      {:ok, 0} -> {:reply, {:error, :already_exists}, {conn, :redis}}
    end
  end

  def handle_call({:remove_member, key, value}, _from, {conn, :redis}) do
    case Redix.command(conn, ["SREM", key, value]) do
      {:ok, 1} -> {:reply, :ok, {conn, :redis}}
      {:ok, 0} -> {:reply, :error, {conn, :redis}}
    end
  end

  def handle_call({:get, key}, _from, {conn, :redis}) do
    with {:ok, type} <- Redix.command(conn, ["TYPE", Redis.namespace(key)]),
      do: Redis.get(type, conn, key)
  end

  def handle_call({:remove, key}, _from, {conn, :redis}) do
    {:ok, _} = Redix.command(conn, ["DEL", Redis.namespace(key)])
    {:reply, :ok, {conn, :redis}}
  end

  def handle_call({:set, key, value}, _from, {conn, :redis}) when is_map(value) do
    command = Enum.reduce(value, [Redis.namespace(key), "HMSET"], fn {k, v}, acc -> [[v, k] | acc] end)

    case Redix.command(conn, command |> List.flatten() |> Enum.reverse()) do
      {:ok, "OK"} -> {:reply, {:ok, value}, {conn, :redis}}
    end
  end

  def handle_call({:set, key, value}, _from, {conn, :redis}) when is_binary(value) do
    case Redix.command(conn, ["SETNX", Redis.namespace(key), value]) do
      {:ok, 1} -> {:reply, {:ok, value}, {conn, :redis}}
      {:ok, 0} -> {:reply, {:error, :already_set}, {conn, :redis}}
    end
  end

  defp create_store do
    if is_nil(Upstream.config(:redis_url)) do
      {:ok, :ets.new(__MODULE__, [:set, :private, :named_table]), :ets}
    else
      {:ok, conn} = Redix.start_link(Upstream.config(:redis_url))
      {:ok, conn, :redis}
    end
  end
end
