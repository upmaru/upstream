defmodule Upstream.B2.LargeFile do
  @moduledoc """
  Public facing api for B2 LargeFile
  """

  alias Upstream.B2.LargeFile.{
    Start,
    Cancel,
    Finish,
    Unfinished
  }

  @spec start(String.t()) :: {:ok | :error, %Start{} | struct}
  @doc """
  `Upstream.B2.LargeFile.start/1` Starts the uploading of the large_file on b2
  """
  def start(file_name) do
    Start.call(body: file_name)
  end

  def start(file_name, metadata) do
    Start.call(body: %{file_name: file_name, file_info: metadata})
  end

  def finish(file_id, sha1_array) do
    Finish.call(
      body: [
        file_id: file_id,
        sha1_array: sha1_array
      ]
    )
  end

  @spec cancel(String.t()) :: {:ok | :error, %Cancel{} | struct}
  def cancel(file_id), do: Cancel.call(body: file_id)

  def unfinished, do: Unfinished.call()
end
