defmodule Upstream.Store.Redis do
  @moduledoc """
  Callbacks for Redis
  Handles redis specific commands
  """

  @namespace "upstream_store"

  def get("hash", conn, key) do
    case Redix.command(conn, ["HGETALL", namespace(key)]) do
      {:ok, []} ->
        {:reply, {:ok, nil}, {conn, :redis}}

      {:ok, value} ->
        {
          :reply,
          value
          |> Enum.chunk(2)
          |> Enum.map(fn [a, b] -> {a, b} end)
          |> Map.new(),
          {conn, :redis}
        }
    end
  end

  def get("string", conn, key) do
    case Redix.command(conn, ["GET", namespace(key)]) do
      {:ok, nil} -> {:reply, {:ok, nil}, {conn, :redis}}
      {:ok, value} -> {:reply, {:ok, value}, {conn, :redis}}
    end
  end

  def namespace(k) do
    @namespace <> ":" <> k
  end
end
