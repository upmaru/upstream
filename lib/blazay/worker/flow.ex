defmodule Blazay.Worker.Flow do
  @moduledoc """
  Generates the chunks stream for Worker.File and Worker.LargeFile
  """

  alias Blazay.Worker.{
    Checksum,
    Status
  }

  def generate(stream, index, checksum_pid, status_pid) do
    last_bytes = get_last_bytes(stream)

    Stream.flat_map stream, fn bytes ->
      Checksum.add_bytes_to_hash(bytes, checksum_pid)

      bytes
      |> byte_size
      |> Status.add_bytes_out(status_pid, index)

      if bytes == last_bytes do
        [bytes, Checksum.get_hash(checksum_pid)]
      else
        [bytes]
      end
    end
  end

  defp get_last_bytes(stream) do
    stream |> Stream.take(-1) |> Enum.to_list |> List.first
  end
end
