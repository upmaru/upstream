defmodule Upstream.B2.LargeFile.Cancel do
  @moduledoc """
  Call to cancel un-finished large_files
  """

  defstruct [:file_id, :account_id, :bucket_id, :file_name]

  @type t :: %__MODULE__{
          file_id: String.t(),
          account_id: String.t(),
          bucket_id: String.t(),
          file_name: String.t()
        }

  use Upstream.B2.Base

  def url(auth, _), do: Url.generate(auth.api_url, :cancel_large_file)

  def body(file_id) when is_binary(file_id), do: %{fileId: file_id}
end
