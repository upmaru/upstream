defmodule Blazay.Job.Thread do
  defstruct [:part_url, :checksum, :content_length]

  alias Blazay.B2.Upload

  @type t :: %__MODULE__{
    checksum: String.t,
    content_length: integer,
    part_url: PartUrl.t,
  }

  def prepare(chunk, file_id) do
    %__MODULE__{
      part_url: get_part_url(file_id),
      checksum: calculate_sha(chunk),
      content_length: calculate_length(chunk)
    }
  end

  defp calculate_sha(chunk) do
    chunk 
    |> Enum.reduce(:crypto.hash_init(:sha), fn(bytes, acc) -> 
      :crypto.hash_update(acc, bytes)
    end)
    |> :crypto.hash_final 
    |> Base.encode16
    |> String.downcase
  end

  defp calculate_length(chunk) do
    chunk
    |> Stream.map(&byte_size/1)
    |> Enum.sum
  end

  defp get_part_url(file_id) do
    {:ok, part_url} = Upload.part_url(file_id)
    part_url
  end
end