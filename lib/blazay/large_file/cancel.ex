defmodule Blazay.LargeFile.Cancel do
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

  alias Blazay.Request
  use Request.Caller

  def url, 
    do: Url.generate(Account.authorization.api_url, :cancel_large_file)
  
  def params(file_id) do
    [
      params: [
        fileId: file_id
      ]
    ]
  end
end
