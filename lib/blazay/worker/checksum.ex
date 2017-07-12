defmodule Blazay.Worker.Checksum do
  @moduledoc """
  Calculates the sha from the streaming chunk.
  """

  def start_link do
    Agent.start_link(fn -> :crypto.hash_init(:sha) end)
  end

  def add_bytes_to_hash(bytes, pid) do
    Agent.get_and_update(pid, fn hash ->
      {hash, :crypto.hash_update(hash, bytes)}
    end)
  end

  def get_hash(pid) do
    Agent.get(pid, fn hash -> :crypto.hash_final(hash) end)
  end
end
