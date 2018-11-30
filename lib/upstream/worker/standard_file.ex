defmodule Upstream.Worker.StandardFile do
  @moduledoc """
  Worker for simple file
  """
  use Upstream.Worker.Base

  def task(auth, state) do
    {:ok, checksum} = Checksum.start_link()
    {:ok, url} = Upload.url(auth)

    # single thread
    index = 0

    header = %{
      authorization: url.authorization_token,
      file_name: URI.encode(state.uid.name),
      file_info: state.job.metadata,
      # for sha1 at the end
      content_length: state.job.stat.size + 40,
      x_bz_content_sha1: "hex_digits_at_end"
    }

    body = Flow.generate(state.job.stream, index, checksum)

    try do
      Upload.file(auth, url.upload_url, header, body)
    after
      Checksum.stop(checksum)
    end
  end
end
