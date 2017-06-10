defmodule Blazay.B2.LargeFile do
  alias Blazay.B2.LargeFile.{
    Start,
    Cancel
  }

  @spec start(String.t) :: {:ok | :error, %Start{} | struct}
  def start(file_name) do 
    Start.call(body: file_name)
  end

  @spec cancel(String.t) :: {:ok | :error, %Cancel{} | struct}
  def cancel(file_id), do: Cancel.call(body: file_id)
end