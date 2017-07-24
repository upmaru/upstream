defmodule Blazay.Worker.File do
  @moduledoc """
  Worker for simple file
  """
  use Blazay.Worker.Simple

  # Client API

  def start_link(job) do
    GenServer.start_link(__MODULE__, job, name: via_tuple(job.name))
  end

  # Server Callbacks

  def init(job) do
    {:ok, status} = Status.start_link

    {:ok, %{
      job: job,
      status: status,
      current_state: :started
    }}
  end

  def task(state) do
    {:ok, checksum} = Checksum.start_link
    {:ok, url} = Upload.url

    # single thread
    index = 0

    header = %{
      authorization: url.authorization_token,
      file_name: URI.encode(state.job.name),
      content_length: state.job.stat.size + 40, # for sha1 at the end
      x_bz_content_sha1: "hex_digits_at_end"
    }

    body = Flow.generate(
      state.job.stream, index, checksum, state.status
    )

    case Upload.file(url.upload_url, header, body) do
      {:ok, file} ->
        Checksum.stop(checksum)
        __MODULE__.finish(state.job.name)
        __MODULE__.stop(state.job.name)
        {:ok, file}
      {:error, reason} ->
        {:error, reason}
    end
  end
end
