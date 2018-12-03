defmodule Upstream.Store do
  use GenServer
  require Logger

  use Upstream.Constants

  # API

  @spec start_link(any()) :: {:ok, any()}
  def start_link(_opts) do
    case GenServer.start_link(__MODULE__, :upstream_store, name: {:global, __MODULE__}) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Process.link(pid)
        {:ok, pid}
    end
  end

  @spec exist?(binary()) :: boolean()
  def exist?(key) do
    GenServer.call({:global, __MODULE__}, {:exist?, key})
  end

  @spec add_member(binary(), any()) :: {:ok, any()} | {:error, :already_exists}
  def add_member(key, value) do
    GenServer.call({:global, __MODULE__}, {:add_member, key, value})
  end

  @spec is_member?(binary(), any()) :: boolean()
  def is_member?(key, value) do
    GenServer.call({:global, __MODULE__}, {:is_member?, key, value})
  end

  @spec remove_member(binary(), any()) :: :ok | :error
  def remove_member(key, value) do
    GenServer.call({:global, __MODULE__}, {:remove_member, key, value})
  end

  @spec move_member(binary(), binary(), any()) :: :ok | :error
  def move_member(from, to, value) do
    GenServer.call({:global, __MODULE__}, {:move_member, from, to, value})
  end

  @spec get(binary()) :: any()
  def get(key) do
    GenServer.call({:global, __MODULE__}, {:get, key})
  end

  @spec set(binary(), any()) :: {:ok, any()} | {:error, :already_set}
  def set(key, value) do
    GenServer.call({:global, __MODULE__}, {:set, key, value})
  end

  @spec increment(binary()) :: :ok | :error
  def increment(key) do
    GenServer.call({:global, __MODULE__}, {:increment, key})
  end

  @spec remove(binary()) :: :ok
  def remove(key) do
    GenServer.call({:global, __MODULE__}, {:remove, key})
  end

  # Callbacks

  @impl true
  @spec init(atom()) :: {:ok, atom() | :ets.tid()}
  def init(table) do
    store = :ets.new(table, [:named_table, read_concurrency: true])
    :ets.insert_new(table, {@uploading, MapSet.new([])})
    :ets.insert_new(table, {@errored, MapSet.new([])})

    Logger.info("[Upstream.Store] Started...")
    {:ok, store}
  end

  @impl true
  def handle_call({:exist?, key}, _from, store) do
    case :ets.lookup(store, key) do
      [{k, _value}] when k == key -> {:reply, true, store}
      [] -> {:reply, false, store}
    end
  end

  @impl true
  def handle_call({:add_member, key, value}, _from, store) do
    with [{_k, members}] <- :ets.lookup(store, key),
         {:ok, new_members} <- check_existing_or_add_member(members, value),
         true <- :ets.insert(store, {key, new_members}) do
      {:reply, {:ok, value}, store}
    else
      {:error, :already_exists} ->
        {:reply, {:error, :already_exists}, store}

      [] ->
        new_members = MapSet.new([value])
        :ets.insert_new(store, {key, new_members})
        {:reply, {:ok, value}, store}
    end
  end

  @impl true
  def handle_call({:is_member?, key, value}, _from, store) do
    case :ets.lookup(store, key) do
      [{k, members}] when k == key ->
        {:reply, MapSet.member?(members, value), store}

      [] ->
        {:reply, false, store}
    end
  end

  @impl true
  def handle_call({:remove_member, key, value}, _from, store) do
    with [{_k, members}] <- :ets.lookup(store, key),
         new_members <- MapSet.delete(members, value),
         true <- :ets.insert(store, {key, new_members}) do
      {:reply, :ok, store}
    else
      _ -> {:reply, :error, store}
    end
  end

  @impl true
  def handle_call({:move_member, from, to, value}, _from, store) do
    with [{_origin, origin_members}] <- :ets.lookup(store, from),
         [{_destination, destination_members}] <- :ets.lookup(store, to),
         new_origin_members <- MapSet.delete(origin_members, value),
         new_destination_members <- MapSet.put(destination_members, value),
         true <- :ets.insert(store, {from, new_origin_members}),
         true <- :ets.insert(store, {to, new_destination_members}) do
      {:reply, :ok, store}
    else
      _ -> {:reply, :error, store}
    end
  end

  @impl true
  def handle_call({:get, key}, _from, store) do
    case :ets.lookup(store, key) do
      [{_k, %MapSet{} = list}] ->
        if Enum.count(list) > 0 do
          {:reply, list, store}
        else
          {:reply, nil, store}
        end

      [{_k, value}] ->
        {:reply, value, store}

      [] ->
        {:reply, nil, store}
    end
  end

  @impl true
  def handle_call({:set, key, value}, _from, store) do
    if :ets.insert_new(store, {key, value}) do
      {:reply, {:ok, value}, store}
    else
      {:reply, {:error, :already_set}, store}
    end
  end

  @impl true
  def handle_call({:increment, key}, _from, store) do
    case :ets.lookup(store, key) do
      [{_k, value}] when is_integer(value) ->
        :ets.update_counter(store, key, {2, 1})
        {:reply, :ok, store}

      [] ->
        :ets.update_counter(store, key, {2, 1}, {key, 0})
        {:reply, :ok, store}

      _ ->
        {:reply, :error, store}
    end
  end

  @impl true
  def handle_call({:remove, key}, _from, source) do
    :ets.delete(source, key)
    {:reply, :ok, source}
  end

  defp check_existing_or_add_member(members, value) do
    if MapSet.member?(members, value) do
      {:error, :already_exists}
    else
      {:ok, MapSet.put(members, value)}
    end
  end
end
