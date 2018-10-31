defmodule Upstream.Store.Redis do
  @moduledoc """
  Callbacks for Redis
  Handles redis specific commands
  """

  @namespace "upstream_store"

  def get("hash", conn, key) do
    case Redix.command(conn, ["HGETALL", namespace(key)]) do
      {:ok, []} ->
        {:reply, nil, conn}

      {:ok, value} ->
        {
          :reply,
          value
          |> Enum.chunk_every(2)
          |> Enum.map(fn [a, b] -> {a, b} end)
          |> Map.new(),
          conn
        }
    end
  end

  def get("none", conn, _key), do: {:reply, nil, conn}

  def get("set", conn, key) do
    case Redix.command(conn, ["SMEMBERS", namespace(key)]) do
      {:ok, members} -> {:reply, members, conn}
    end
  end

  def get("string", conn, key) do
    case Redix.command(conn, ["GET", namespace(key)]) do
      {:ok, nil} -> {:reply, nil, conn}
      {:ok, value} -> {:reply, value, conn}
    end
  end

  def namespace(k) do
    @namespace <> ":#{Upstream.config(:bucket_name)}:" <> k
  end
end
