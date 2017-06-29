defmodule Blazay.B2.Upload.Url do
  defstruct [:bucket_id, :upload_url, :authorization_token]

  @type t :: %__MODULE__{
    bucket_id: String.t,
    upload_url: String.t,
    authorization_token: String.t
  }

  use Blazay.B2

  def url(_), do: Account.api_url |> Url.generate(:get_upload_url)
  
  def body(_) do
    %{ bucketId: Blazay.config(:bucket_id) }
  end
end
