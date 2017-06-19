defmodule Blazay.Job.LargeFile.B2.Thread do
  defstruct [:authorization_token, :url, :checksums, :content_length]

  @type t :: %__MODULE__{
    url: String.t,
    checksum: String.t,
    content_length: integer,
    authorization_token: String.t,
  }

  def prepare(chunk) do
    %__MODULE__{
      checksum: calculate_sha(chunk)
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
  end

  defp calculate_length(chunk) do
    chunk
    |> Enum.map(&byte_size/1)
    |> Enum.sum
  end
end