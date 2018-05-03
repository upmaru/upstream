defmodule Upstream.Store.Ets do
  @moduledoc """
  ETS specific commands
  """

  def remove_member(conn, key, list, value) do
    new_list = Enum.reject(list, fn v -> v == value end)
    if Enum.empty?(new_list),
      do: :ets.delete(conn, key),
      else: :ets.insert(conn, {key, new_list})
  end
end
