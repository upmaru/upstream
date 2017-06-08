defmodule Blazay.LargeFile.Start do

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
  
  alias Blazay.Request
  use Request.Caller

  def url, do: Account.api_url |> Url.generate(:start_large_file)

  def params(file_name) do
    [
      params: [
        bucketId: Blazay.config(:bucket_id),
        contentType: "b2/x-auto",
        fileName: file_name
      ]
    ]
  end
end