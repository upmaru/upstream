defmodule Upstream.B2.Download.Authorization do
  @moduledoc """
  This will get_download_authorization for us
  """

  alias Upstream.B2.Account.Authorization

  defstruct [:bucket_id, :file_name_prefix, :authorization_token]

  @type t :: %__MODULE__{
          bucket_id: String.t(),
          file_name_prefix: String.t(),
          authorization_token: String.t()
        }

  use Upstream.B2.Base

  @spec url(Authorization.t(), any()) :: binary()
  def url(auth, _), do: Url.generate(auth.api_url, :get_download_authorization)

  def body(body) do
    %{
      bucketId: Upstream.storage(:bucket_id),
      fileNamePrefix: Keyword.get(body, :prefix),
      validDurationInSeconds: Keyword.get(body, :duration)
    }
  end
end
