defmodule Blazay.LargeFile do
  alias Blazay.LargeFile.{
    Start,
    Cancel
  }

  @spec start(String.t) :: {:ok | :error, %Start{} | struct}
  def start(file_name), do: Start.get(file_name)

  @spec cancel(String.t) :: {:ok | :error, %Cancel{} | struct}
  def cancel(file_id), do: Cancel.get(file_id)
end