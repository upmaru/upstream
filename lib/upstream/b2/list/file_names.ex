defmodule Upstream.B2.List.FileNames do
  @moduledoc """
  Lists files by file name
  """

  defstruct [:files, :next_file_name]

  use Upstream.B2.Base

  def url(_), do: Url.generate(Account.api_url(), :list_file_names)

  def body(file_name) when is_binary(file_name) do
    %{
      bucketId: Upstream.config(:bucket_id),
      startFileName: URI.encode(file_name),
      prefix: Path.dirname(file_name)
    }
  end
end
