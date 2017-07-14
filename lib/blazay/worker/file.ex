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

  require Logger

  def start_link(job) do
    GenServer.start_link(__MODULE__, job, name: via_tuple(job.name))
  end

  def init(job) do
    {:ok, status} = Status.start_link

    {:ok, url} = Upload.url

    {:ok, %{
      job: job,
      url: url,
      status: status,
      current_state: :started
    }}
  end

  def upload(job_name) do
    GenServer.cast(via_tuple(job_name), :upload)
  end

  def finish(job_name) do
    GenServer.call(via_tuple(job_name), :finish)
  end

  def stop(job_name) do
    GenServer.call(via_tuple(job_name), :stop)
  end

  def handle_cast(:upload, state) do
    Task.Supervisor.start_child TaskSupervisor, fn ->
      upload_stream(state)
    end

    new_state = Map.merge(state, %{current_state: :uploading})

    {:noreply, new_state}
  end

  def handle_call(:finish, _from, state) do
    new_state = Map.merge(state, %{current_state: :finished})
    {:reply, :finished, new_state}
  end

  def handle_call(:stop, _from, state) do
    Status.stop(state.status)

    case state.current_state do
      the_state when the_state in [:started, :uploading] ->
        Logger.info "-----> Cancelling #{state.job.name}"
        {:stop, :shutdown, state}
      :finished ->
        Logger.info "-----> #{state.job.name} #{Atom.to_string(new_state.current_state)}"
        {:stop, :shutdown, state}
    end
  end

  def terminate(reason, state) do
    Logger.info "-----> Shutting down #{state.job.name}"
    reason
  end

  defp upload_stream(state) do
    {:ok, checksum} = Checksum.start_link

    header = %{
      authorization: state.url.authorization_token,
      file_name: URI.encode(state.job.name),
      content_length: state.job.stat.size + 40, # for sha1 at the end
      x_bz_content_sha1: "hex_digits_at_end"
    }

    last_bytes = get_last_bytes(state.job.stream)

    stream = Stream.flat_map state.job.stream, fn bytes ->
      Checksum.add_bytes_to_hash(bytes, checksum)

      bytes
      |> byte_size
      |> Status.add_bytes_out(state.status)

      if bytes == last_bytes do
        [bytes, Checksum.get_hash(checksum)]
      else
        [bytes]
      end
    end

    {:ok, file} = Upload.file(state.url.upload_url, header, stream)
    Status.add_uploaded({0, file.content_sha1}, state.status)

    if Status.upload_complete?(state.status) do
      Checksum.stop(checksum)
      __MODULE__.finish(state.job.name)
      __MODULE__.stop(state.job.name)
    end
  end

  defp get_last_bytes(stream) do
    stream |> Stream.take(-1) |> Enum.to_list |> List.first
  end

  defp via_tuple(job_name) do
    {:via, Registry, {Blazay.Uploader.Registry, job_name}}
  end
end
