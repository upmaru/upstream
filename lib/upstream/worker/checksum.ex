defmodule Upstream.Worker.Checksum do
  @moduledoc """
  Calculates the sha from the streaming chunk.
  """

  @spec start_link() :: {:error, any()} | {:ok, pid()}
  def start_link do
    Agent.start_link(fn -> :crypto.hash_init(:sha) end)
  end

  @spec add_bytes_to_hash(any(), atom() | pid() | {atom(), any()} | {:via, atom(), any()}) ::
          any()
  def add_bytes_to_hash(bytes, pid) do
    Agent.get_and_update(pid, fn hash ->
      {hash, :crypto.hash_update(hash, bytes)}
    end)
  end

  @spec stop(atom() | pid() | {atom(), any()} | {:via, atom(), any()}) :: :ok
  def stop(pid), do: Agent.stop(pid)

  @spec get_hash(atom() | pid() | {atom(), any()} | {:via, atom(), any()}) :: any()
  def get_hash(pid) do
    Agent.get(pid, &hash_to_string/1)
  end

  defp hash_to_string(hash) do
    hash
    |> :crypto.hash_final()
    |> Base.encode16()
    |> String.downcase()
  end
end
