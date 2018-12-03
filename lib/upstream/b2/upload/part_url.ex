defmodule Upstream.B2.Upload.PartUrl do
  @moduledoc """
  Gets the part URL from B2
  """

  alias Upstream.B2.Account.Authorization

  defstruct [
    :file_id,
    :upload_url,
    :authorization_token
  ]

  @type t :: %__MODULE__{
          file_id: String.t(),
          upload_url: String.t(),
          authorization_token: String.t()
        }

  use Upstream.B2.Base

  @spec url(Authorization.t(), any()) :: binary()
  def url(auth, _), do: Url.generate(auth.api_url, :get_upload_part_url)

  def body(file_id), do: %{fileId: file_id}
end
