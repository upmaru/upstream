defmodule Blazay.Upload.PartUrl do
  alias Blazay.Request
  use Request.Caller

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

  @spec call(String.t) :: {:ok | :error, struct}
  def call(file_id) do
    %__MODULE__{}
    |> Request.get(url(), [Account.authorization_header], params: [file_id: file_id])
  end

  defp url, do: Url.generate(Account.authorization.api_url, :get_upload_part_url)
end