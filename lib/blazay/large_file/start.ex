defmodule Blazay.LargeFile.Start do
  use Blazay.Request
  @behaviour Blazay.Request

  alias Blazay.{Error, Account}

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

  @spec call(String.t) :: {:ok | :error, %__MODULE__{} | %Error{}}
  def call(file_name) do
    url = Url.generate(Account.authorization.api_url, :start_large_file)

    case get(url, [Account.authorization_header], params: params(file_name)) do
      {:ok, %{status_code: 200, body: body}} -> 
        body |> render()
      {:ok, %{status_code: _, body: body}} ->
        body |> Error.render()
    end
  end

  defp params(file_name) do
    [bucketId: Blazay.config(:bucket_id),
     contentType: "b2/x-auto", 
     fileName: file_name]
  end

  defp render(body) do
    response = Poison.decode!(body)

    {:ok, %__MODULE__{
      file_id: response["fileId"],
      file_name: response["fileName"],
      account_id: response["accountId"],
      bucket_id: response["bucketId"],
      content_type: response["contentType"],
      file_info: response["fileInfo"],
      upload_timestamp: response["uploadTimestamp"]
    }}
  end
end