defmodule Upstream.B2.Delete.FileVersion do
  @moduledoc """
  Delete file version
  """

  alias Upstream.B2.Account.Authorization

  defstruct [
    :file_id,
    :file_name
  ]

  use Upstream.B2.Base

  @spec url(Authorization.t(), any()) :: binary()
  def url(auth, _), do: Url.generate(auth.api_url, :delete_file_version)

  def body(body) do
    file_id = Keyword.get(body, :file_id)
    file_name = Keyword.get(body, :file_name)

    %{fileName: file_name, fileId: file_id}
  end
end
