defmodule Upstream.B2.Upload.Url do
  @moduledoc """
  Responsible for retrieving the upload_url from b2 for simple file
  """
  defstruct [:bucket_id, :upload_url, :authorization_token]

  @type t :: %__MODULE__{
          bucket_id: String.t(),
          upload_url: String.t(),
          authorization_token: String.t()
        }

  use Upstream.B2.Base

  @spec url(atom() | %{api_url: any()}, any()) :: binary()
  def url(auth, _), do: Url.generate(auth.api_url, :get_upload_url)

  def body(_) do
    %{bucketId: Upstream.storage(:bucket_id)}
  end
end
