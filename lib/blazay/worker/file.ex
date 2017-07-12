defmodule Blazay.Worker.File do
  @moduledoc """
  Worker for simple file
  """
  use GenServer

  alias Blazay.B2.{
    Upload
  }

  alias Blazay.Uploader.TaskSupervisor

  alias Blazay.Worker.{
    Status, Checksum
  }

  def start_link(job) do
    GenServer.start_link(__MODULE__, job, name: via_tuple(job.name))
  end

  def init(job) do
    {:ok, status} = Status.start_link
    {:ok, checksum} = Checksum.start_link

    {:ok, upload_url} = Upload.url

    {:ok, %{
      job: job,
      upload_url: upload_url,
      status: status,
      checksum: checksum,
      current_state: :started
    }}
  end

  def upload(job_name) do
    GenServer.cast(via_tuple(job_name), :upload)
  end

  def handle_cast(:upload, state) do
    Task.Supervisor.start_child TaskSupervisor, fn ->
      upload_stream(state)
    end

    new_state = Map.merge(state, %{current_state: :uploading})

    {:noreply, new_state}
  end

  defp upload_stream(state) do
    header = %{
      authorization: state.upload_url.authorization_token,
      file_name: state.job.name,
      content_length: state.stat.size + 40, # for sha1 at the end
      x_bz_content_sha1: "hex_digits_at_end"
    }

    last_bytes =
      state.job.stream
      |> Stream.take(-1)
      |> Enum.to_list
      |> List.first

    stream = Stream.flat_map state.job.stream, fn bytes ->
      Checksum.add_bytes_to_hash(bytes, state.checksum)

      if bytes == last_bytes do
        hash =
          state.checksum
          |> Checksum.get_hash
          |> Base.encode16
          |> String.downcase

        [bytes, hash]
      else
        [bytes]
      end
    end
  end

  defp via_tuple(job_name) do
    {:via, Registry, {Blazay.Uploader.Registry, job_name}}
  end
end
