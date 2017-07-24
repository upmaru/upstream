defmodule Blazay.Worker.StandardFile do
  @moduledoc """
  Worker for simple file
  """
  use Blazay.Worker.Simple

  def task(state) do
    {:ok, checksum} = Checksum.start_link
    {:ok, url} = Upload.url

    # single thread
    index = 0

    header = %{
      authorization: url.authorization_token,
      file_name: URI.encode(state.uid.name),
      content_length: state.job.stat.size + 40, # for sha1 at the end
      x_bz_content_sha1: "hex_digits_at_end"
    }

    body = Flow.generate(state.job.stream, index, checksum)

    case Upload.file(url.upload_url, header, body) do
      {:ok, file} ->
        Checksum.stop(checksum)
        finish(state.uid.name)
        stop(state.uid.name)
        {:ok, file}
      {:error, reason} -> {:error, reason}
    end
  end
end
