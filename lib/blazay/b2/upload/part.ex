defmodule Blazay.B2.Upload.Part do
  defstruct [:file_id, :part_number, :content_length, :content_sha1]

  @type t :: %__MODULE__{
    file_id: String.t,
    part_number: String.t,
    content_length: String.t,
    content_sha1: String.t
  }

  use Blazay.B2.Base

  def url(upload_url) when is_binary(upload_url), do: upload_url

  def header(part_data) do
    [
      {"Authorization", part_data.authorization},
      {"X-Bz-Part-Number", part_data.x_bz_part_number},
      {"Content-Length", part_data.content_length},
      {"X-Bz-Content-Sha1", part_data.x_bz_content_sha1}
    ]
  end

  def body(body), do: {:stream, body}
end
