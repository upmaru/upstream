defmodule Blazay.LargeFile.Start do
  alias Blazay.Request
  use Request.Caller

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

  @spec call(String.t) :: {:ok | :error, struct}
  def call(file_name) do
    %__MODULE__{}
    |> Request.get(url(), [Account.authorization_header], params: params(file_name))
  end

  defp url, do: Url.generate(Account.authorization.api_url, :start_large_file)

  defp params(file_name) do
    [bucketId: Blazay.config(:bucket_id),
     contentType: "b2/x-auto", 
     fileName: file_name]
  end
end