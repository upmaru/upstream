defmodule Blazay.Upload.PartUrl do

  defstruct [
    :file_id,
    :upload_url,
    :authorization_token
  ]

  @type t :: %__MODULE__{
    file_id: String.t,
    upload_url: String.t,
    authorization_token: String.t
  }
  
  alias Blazay.Request
  use Request.Caller

  def url, 
    do: Url.generate(Account.authorization.api_url, :get_upload_part_url)
  
  def params(file_id) do
    [
      params: [fileId: file_id]
    ]
  end
end
