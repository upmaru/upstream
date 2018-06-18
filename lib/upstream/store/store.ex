defmodule Upstream.Store do
  @moduledoc """
  The Store module is used to store the state of uploads. 
  If you are using the Upstream module in a distributed system you will need to,
  set the redis_url: option for upstream, as uploads can happen from any of your node.
  """
  use GenServer
  require Logger

  alias Upstream.Store.{
    Redis
  }

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def exist?(key) do
    GenServer.call(__MODULE__, {:exist?, key})
  end

  def flush_all do
    GenServer.call(__MODULE__, :flush_all)
  end

  def add_member(key, value) do
    GenServer.call(__MODULE__, {:add_member, key, value})
  end

  def is_member?(key, value) do
    GenServer.call(__MODULE__, {:is_member?, key, value})
  end

  def remove_member(key, value) do
    GenServer.call(__MODULE__, {:remove_member, key, value})
  end

  def move_member(from, to, value) do
    GenServer.call(__MODULE__, {:move_member, from, to, value})
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def set(key, value) do
    GenServer.call(__MODULE__, {:set, key, value})
  end

  def increment(key) do
    GenServer.call(__MODULE__, {:increment, key})
  end

  def remove(key) do
    GenServer.call(__MODULE__, {:remove, key})
  end

  # Callbacks

  def init(:ok) do
    if is_nil(Upstream.config(:redis_url)) do
      Logger.info("[Upstream] No redis config, Store calls will result in noop.")
      {:ok, :no_store}
    else
      Redix.start_link(Upstream.config(:redis_url))
    end
  end

  def handle_call({:exist?, _key}, _from, :no_store), do: noop()
  def handle_call({:exist?, key}, _from, conn) do
    case Redix.command(conn, ["EXISTS", Redis.namespace(key)]) do
      {:ok, 0} -> {:reply, false, conn}
      {:ok, 1} -> {:reply, true, conn}
    end
  end

  def handle_call(:flush_all, _from, :no_store), do: noop()
  def handle_call(:flush_all, _from, conn) do
    {:ok, keys} = Redix.command(conn, ["KEYS", Redis.namespace("*")])

    if Enum.empty?(keys) do
      {:reply, :ok, conn}
    else
      {:ok, _count} = Redix.command(conn, ["DEL" | keys])
      {:reply, :ok, conn}
    end
  end

  def handle_call({:is_member?, _key, _value}, _from, :no_store), do: noop()
  def handle_call({:is_member?, key, value}, _from, conn) do
    case Redix.command(conn, ["SISMEMBER", Redis.namespace(key), value]) do
      {:ok, 1} -> {:reply, true, conn}
      {:ok, 0} -> {:reply, false, conn}
    end
  end

  def handle_call({:move_member, _from_val, _to, _value}, _from, :no_store), do: noop()
  def handle_call({:move_member, from, to, value}, _from, conn) do
    case Redix.command(conn, ["SMOVE", Redis.namespace(from), Redis.namespace(to), value]) do
      {:ok, 1} -> {:reply, :ok, conn}
      {:ok, 0} -> {:reply, :error, conn}
    end
  end

  def handle_call({:add_member, _key, _value}, _from, :no_store), do: noop()
  def handle_call({:add_member, key, value}, _from, conn) do
    case Redix.command(conn, ["SADD", Redis.namespace(key), value]) do
      {:ok, 1} -> {:reply, {:ok, value}, conn}
      {:ok, 0} -> {:reply, {:error, :already_exists}, conn}
    end
  end

  def handle_call({:remove_member, _key, _value}, _from, :no_store), do: noop()
  def handle_call({:remove_member, key, value}, _from, conn) do
    case Redix.command(conn, ["SREM", Redis.namespace(key), value]) do
      {:ok, 1} -> {:reply, :ok, conn}
      {:ok, 0} -> {:reply, :error, conn}
    end
  end

  def handle_call({:get, _key}, _from, :no_store), do: noop()
  def handle_call({:get, key}, _from, conn) do
    with {:ok, type} <- Redix.command(conn, ["TYPE", Redis.namespace(key)]),
         do: Redis.get(type, conn, key)
  end

  def handle_call({:increment, _key}, _from, :no_store), do: noop()
  def handle_call({:increment, key}, _from, conn) do
    {:ok, _} = Redix.command(conn, ["INCR", Redis.namespace(key)])
    {:reply, :ok, conn}
  end

  def handle_call({:remove, _key}, _from, :no_store), do: noop()
  def handle_call({:remove, key}, _from, conn) do
    {:ok, _} = Redix.command(conn, ["DEL", Redis.namespace(key)])
    {:reply, :ok, conn}
  end

  def handle_call({:set, _key, _value}, _from, :no_store), do: noop()
  def handle_call({:set, key, value}, _from, conn) when is_map(value) do
    command =
      Enum.reduce(value, [Redis.namespace(key), "HMSET"], fn {k, v}, acc -> [[v, k] | acc] end)

    case Redix.command(conn, command |> List.flatten() |> Enum.reverse()) do
      {:ok, "OK"} -> {:reply, {:ok, value}, conn}
    end
  end

  def handle_call({:set, key, value}, _from, conn) when is_binary(value) do
    case Redix.command(conn, ["SETNX", Redis.namespace(key), value]) do
      {:ok, 1} -> {:reply, {:ok, value}, conn}
      {:ok, 0} -> {:reply, {:error, :already_set}, conn}
    end
  end

  defp noop, do: {:reply, :ok, :no_store}
end
