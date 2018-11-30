defmodule Upstream.Worker.Chunk do
  @moduledoc """
  Handles uploading of chunks (pieces from the client)
  """

  use Upstream.Worker.Base

  def task(auth, state) do
    with {:ok, checksum} <- Checksum.start_link(),
         {:ok, part_url} <- Upload.part_url(auth, state.uid.file_id) do
      index = state.uid.index

      header = %{
        authorization: part_url.authorization_token,
        x_bz_part_number: index + 1,
        content_length: state.job.content_length + 40,
        x_bz_content_sha1: "hex_digits_at_end"
      }

      body = Flow.generate(state.job.stream, index, checksum)

      try do
        Upload.part(auth, part_url.upload_url, header, body)
      after
        Checksum.stop(checksum)
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
