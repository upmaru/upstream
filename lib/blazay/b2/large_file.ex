defmodule Blazay.B2.LargeFile do
  alias Blazay.B2.LargeFile.{
    Start,
    Cancel,
    Finish, 
    Unfinished
  }

  @spec start(String.t) :: {:ok | :error, %Start{} | struct}
  def start(file_name) do 
    Start.call(body: file_name)
  end

  def finish(file_id, sha1_array) do
    Finish.call(body: [file_id: file_id, sha1_array: sha1_array])
  end

  @spec cancel(String.t) :: {:ok | :error, %Cancel{} | struct}
  def cancel(file_id), do: Cancel.call(body: file_id)

  def unfinished, do: Unfinished.call
end