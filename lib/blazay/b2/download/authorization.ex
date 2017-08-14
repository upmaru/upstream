defmodule Blazay.B2.Download.Authorization do
  @moduledoc """
  This will get_download_authorization for us
  """

  defstruct [:bucket_id, :file_name_prefix, :authorization_token]

  @type t :: %__MODULE__{
    bucket_id: String.t,
    file_name_prefix: String.t,
    authorization_token: String.t
  }

  use Blazay.B2.Base

  def url(_), do: Url.generate(Account.api_url, :get_download_authorization)

  def body(body) do
    %{
      bucketId: Blazay.config(:bucket_id),
      fileNamePrefix: Keyword.get(body, :prefix),
      validDurationInSeconds: Keyword.get(body, :duration)
    }
  end
end
