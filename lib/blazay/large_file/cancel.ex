defmodule Blazay.LargeFile.Cancel do
  alias Blazay.Request
  use Request.Caller

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

  @spec call(String.t) :: {:ok | :error, struct}
  def call(file_id) do
    %__MODULE__{}
    |> Request.get(url(), [Account.authorization_header], params: [fileId: file_id])
  end

  defp url, do: Url.generate(Account.authorization.api_url, :cancel_large_file)
end
