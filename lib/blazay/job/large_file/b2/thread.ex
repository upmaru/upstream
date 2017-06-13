defmodule Blazay.Job.LargeFile.B2.Thread do
  defstruct [:url, :checksums, :content_length]

  @type t :: %__MODULE__{
    url: String.t,
    checksums: List.t,
    content_length: integer
  }

  def prepare(stream) do
    %__MODULE__{
      checksums: calculate_sha(stream)
    }
  end

  def calculate_sha(stream) do
    Enum.map(stream, &calculate_sha_for_chunk/1) 
  end

  defp calculate_sha_for_chunk(chunk) do
    chunk 
    |> Enum.reduce(:crypto.hash_init(:sha), fn(bytes, acc) -> 
      :crypto.hash_update(acc, bytes)
    end)
    |> :crypto.hash_final 
    |> Base.encode16
  end
end