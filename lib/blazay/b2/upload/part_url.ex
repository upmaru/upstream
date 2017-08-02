defmodule Blazay.B2.Upload.PartUrl do
  @moduledoc """
  Gets the part URL from B2
  """
  
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

  use Blazay.B2.Base

  def url(_), do: Url.generate(Account.api_url, :get_upload_part_url)

  def body(file_id), do: %{fileId: file_id}
end
