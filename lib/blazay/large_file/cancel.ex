defmodule Blazay.LargeFile.Cancel do
  use Blazay.Request

  defstruct [
    :file_id,
    :account_id,
    :bucket_id,
    :file_name
  ]

  @type t :: %__MODULE__{
    file_id: String.t,
    account_id: String.t,
    bucket_id: String.t,
    file_name: String.t
  }

  @spec call(String.t) :: {:ok | :error, %__MODULE__{} | %Error{}}
  def call(file_id) do
    url = Url.generate(Account.authorization.api_url, :cancel_large_file)

    case get(url, [Account.authorization_header], params: [fileId: file_id]) do
      {:ok, %{status_code: 200, body: body}} -> body
      {:ok, %{status_code: _, body: body}} -> body
    end
  end
end