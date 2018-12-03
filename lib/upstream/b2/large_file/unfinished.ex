defmodule Upstream.B2.LargeFile.Unfinished do
  @moduledoc """
  This module retrieves Unfinished LargeFiles
  ## Examples

    iex> Upstream.B2.LargeFile.Unfinished.call()
    {:ok, %Upstream.B2.LargeFile.Unfinished{}}
  """
  defstruct [:files, :next_file_id]

  @type t() :: %__MODULE__{
          files: List.t(),
          next_file_id: String.t()
        }

  use Upstream.B2.Base

  def url(auth, _), do: Url.generate(auth.api_url, :list_unfinished_large_files)

  def body(_) do
    %{bucketId: Upstream.storage(:bucket_id)}
  end
end
