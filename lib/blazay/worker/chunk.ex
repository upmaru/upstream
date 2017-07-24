defmodule Blazay.Worker.Chunk do
  @moduledoc """
  Handles uploading of chunks (pieces from the client)
  """
  use Blazay.Worker.Simple

  def task(state) do
    {:ok, checksum} = Checksum.start_link
    {:ok, part_url} = Upload.part_url(state.uid.file_id)

    index = state.uid.index

    header = %{
      authorization: part_url.authorization_token,
      x_bz_part_number: (index + 1),
      content_length: state.job.content_length + 40,
      x_bz_content_sha1: "hex_digits_at_end"
    }

    body = Flow.generate(state.job.stream, index, checksum)

    case Upload.part(part_url.upload_url, header, body) do
      {:ok, part} ->
        Checksum.stop(checksum)
        __MODULE__.finish(state.uid.name)
        __MODULE__.stop(state.uid.name)
        {:ok, part}
      {:error, reason} -> {:error, reason}
    end
  end
end
