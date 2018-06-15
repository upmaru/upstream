defmodule Upstream.B2.Delete.FileVersion do
  defstruct [
    :file_id,
    :file_name
  ]

  use Upstream.B2.Base

  def url(_), do: Url.generate(Account.api_url(), :delete_file_version)

  def body(body) do
    file_id = Keyword.get(body, :file_id)
    file_name = Keyword.get(body, :file_name)

    %{fileName: file_name, fileId: file_id}
  end
end
