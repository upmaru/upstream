defmodule Upstream.Worker.StandardFile do
  @moduledoc """
  Worker for simple file
  """
  use Upstream.Worker.Base

  alias Upstream.Job

  @impl true
  @spec task(%{job: Job.t()}) :: {:error, struct} | {:ok, struct}
  def task(%{job: %Job{authorization: auth, uid: uid, stat: stat, metadata: metadata, stream: stream}} = _state) do
    {:ok, checksum} = Checksum.start_link()
    {:ok, url} = Upload.url(auth)

    # single thread
    index = 0

    header = %{
      authorization: url.authorization_token,
      file_name: URI.encode(uid.name),
      file_info: metadata,
      # for sha1 at the end
      content_length: stat.size + 40,
      x_bz_content_sha1: "hex_digits_at_end"
    }

    body = Flow.generate(stream, index, checksum)

    try do
      Upload.file(auth, url.upload_url, header, body)
    after
      Checksum.stop(checksum)
    end
  end
end
