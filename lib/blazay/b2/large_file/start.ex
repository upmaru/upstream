defmodule Blazay.B2.LargeFile.Start do
  defstruct [
    :file_id,
    :file_name,
    :account_id,
    :bucket_id,
    :content_type,
    :file_info,
    :upload_timestamp
  ]

  @type t :: %__MODULE__{
    file_id: String.t,
    file_name: String.t,
    account_id: String.t,
    bucket_id: String.t,
    content_type: String.t,
    file_info: map,
    upload_timestamp: integer
  }

  use Blazay.B2.Base

  def url(_), do: Url.generate(Account.api_url, :start_large_file)

  def body(file_name) when is_binary(file_name) do
    %{
      bucketId: Blazay.config(:bucket_id),
      contentType: "b2/x-auto",
      fileName: URI.encode(file_name)
    }
  end
end
