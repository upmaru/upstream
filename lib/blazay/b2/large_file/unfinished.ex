defmodule Blazay.B2.LargeFile.Unfinished do
  defstruct [:files, :next_file_id]

  @type t() :: %__MODULE__{
    files: List.t,
    next_file_id: String.t
  }

  use Blazay.B2

  def url(_), do: Account.api_url |> Url.generate(:list_unfinished_large_files)

  def body(_) do
    %{ bucketId: Blazay.config(:bucket_id) }
  end
end