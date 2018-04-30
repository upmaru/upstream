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

  def register(key, value) do
    GenServer.call(__MODULE__, {:register, key, value})
  end

  def unregister(key) do
    GenServer.call(__MODULE__, {:unregister, key})
  end

  def register_name({_registry, key}, pid) when pid == self() do
    GenServer.call(__MODULE__, {:register_name, key, pid})
  end

  def unregister_name({_registry, key}) do
    GenServer.call(__MODULE__, {:unregister_name, key})
  end

  def whereis_name({_registry, key}) do
    GenServer.call(__MODULE__, {:whereis_name, key})
  end

  def clear() do
    GenServer.call(__MODULE__, :clear)
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

  def handle_call({:exist?, key}, _from, {conn, :registry}) do
    case Registry.lookup(conn, key) do
      [{_pid, nil}] -> {:reply, true, {conn, :registry}}
      [] -> {:reply, false, {conn, :registry}}
    end
  end

  def handle_call({:unregister, key}, _from, {conn, :redis}) do
    {:ok, _} = Redix.command(conn, ["DEL", get_key(key)])
    {:reply, :ok, {conn, :redis}}
  end

  def handle_call({:unregister, key}, _from, {conn, :registry}) do
    :ok = Registry.unregister(conn, key)
    {:reply, :ok, {conn, :registry}}
  end

  def handle_call({:register, key, value}, _from, {conn, :redis}) do
    case Redix.command(conn, ["SETNX", get_key(key), value]) do
      {:ok, 1} -> {:reply, {:ok, value}, {conn, :redis}}
      {:ok, 0} -> {:reply, {:error, :already_set}, {conn, :redis}}
    end
  end

  def handle_call({:register, key, value}, _from, {conn, :registry}) do
    case Registry.register(conn, key, value) do
      {:ok, _pid} ->
        {:reply, {:ok, value}, {conn, :registry}}

      {:error, {:already_registered, _pid}} ->
        {:reply, {:error, :already_set}, {conn, :registry}}
    end
  end

  def handle_call({:whereis_name, key}, _from, {conn, :redis}) do
    case Redix.command(conn, ["GET", get_key(key)]) do
      {:ok, nil} -> {:reply, :undefined, {conn, :redis}}
      {:ok, value} ->
        "#PID" <> string = value
        pid =
          string
          |> :erlang.binary_to_list
          |> :erlang.list_to_pid

        if Process.alive?(pid) do
          {:reply, pid, {conn, :redis}}
        else
          {:reply, :undefined, {conn, :redis}}
        end
    end
  end

  def handle_call({:whereis_name, key}, _from, {conn, :registry}) do
    {:reply, Registry.whereis_name({conn, key}), {conn, :registry}}
  end

  def handle_call({:register_name, key, pid}, _from, {conn, :redis}) do
    case Redix.command(conn, ["SET", get_key(key), inspect(pid)]) do
      {:ok, "OK"} -> {:reply, :yes, {conn, :redis}}
      {:ok, nil} -> {:reply, :no, {conn, :redis}}
    end
  end

  def handle_call({:register_name, key, pid}, _from, {conn, :registry}) do
    {:reply, Registry.register_name({conn, key}, pid), {conn, :registry}}
  end

  def handle_call(:clear, _from, {conn, :redis}) do
    with {:ok, keys} <- Redix.command(conn, ["KEYS", prefix() <> ":*"]) do
      {:reply, Redix.command(conn, ["DEL", keys]), {conn, :redis}}
    end
  end

  defp create_store() do
    if is_nil(Upstream.config(:redis_url)) do
      {:ok, conn} = Registry.start_link(keys: :unique)
      {:ok, conn, :registry}
    else
      {:ok, conn} = Redix.start_link(Upstream.config(:redis_url))
      {:ok, conn, :redis}
    end
  end

  defp get_key(key) do
    prefix() <> ":" <> key
  end

  defp prefix do
    with {:ok, hostname} <- :inet.gethostname(),
      do: @namespace <> ":" <> List.to_string(hostname)
  end
end
