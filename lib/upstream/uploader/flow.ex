defmodule Upstream.Uploader.Flow do
  @moduledoc """
  Generates the chunks stream for Worker.File and Worker.LargeFile
  """

  alias Upstream.Uploader.Checksum
  alias Upstream.Worker.LargeFile.Status

  @spec generate(any(), any(), any(), any()) :: (any(), any() -> any())
  def generate(stream, index, checksum_pid, status_pid \\ nil) do
    last_bytes = get_last_bytes(stream)

    Stream.flat_map(stream, fn bytes ->
      Checksum.add_bytes_to_hash(bytes, checksum_pid)

      if status_pid do
        bytes
        |> byte_size
        |> Status.add_bytes_out(status_pid, index)
      end

      if bytes == last_bytes do
        [bytes, Checksum.get_hash(checksum_pid)]
      else
        [bytes]
      end
    end)
  end

  defp get_last_bytes(stream) do
    stream |> Stream.take(-1) |> Enum.to_list() |> List.first()
  end
end
