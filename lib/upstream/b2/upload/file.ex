defmodule Upstream.B2.Upload.File do
  @moduledoc """
  Upload Standard File
  """
  @derive Jason.Encoder

  defstruct [
    :file_id,
    :file_name,
    :account_id,
    :bucket_id,
    :content_length,
    :content_sha1,
    :content_type,
    :file_info,
    :action,
    :upload_timestamp
  ]

  @type t :: %__MODULE__{
          file_id: String.t(),
          file_name: String.t(),
          account_id: String.t(),
          bucket_id: String.t(),
          content_length: integer,
          content_sha1: String.t(),
          content_type: String.t(),
          file_info: map,
          action: String.t(),
          upload_timestamp: integer
        }

  use Upstream.B2.Base

  @spec url(any(), binary()) :: binary()
  def url(_auth, upload_url) when is_binary(upload_url), do: upload_url

  def header(_auth, file_data) do
    metadata =
      file_data
      |> Map.get(:file_info, %{})
      |> Enum.map(fn {key, val} -> {"X-Bz-Info-#{key}", val} end)

    [
      {"Authorization", file_data.authorization},
      {"X-Bz-File-Name", file_data.file_name},
      {"Content-Type", "b2/x-auto"},
      {"Content-Length", file_data.content_length},
      {"X-Bz-Content-Sha1", file_data.x_bz_content_sha1}
      | metadata
    ]
  end

  def body(body), do: {:stream, body}
end
