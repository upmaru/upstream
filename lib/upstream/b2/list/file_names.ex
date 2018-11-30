defmodule Upstream.B2.List.FileNames do
  @moduledoc """
  Lists files by file name
  """

  alias Upstream.B2.Account.Authorization

  defstruct [:files, :next_file_name]

  use Upstream.B2.Base

  @spec url(Authorization.t(), any()) :: binary()
  def url(auth, _), do: Url.generate(auth.api_url, :list_file_names)

  def body(file_name) when is_binary(file_name) do
    %{
      bucketId: Upstream.storage(:bucket_id),
      startFileName: URI.encode(file_name),
      prefix: Path.dirname(file_name)
    }
  end
end
