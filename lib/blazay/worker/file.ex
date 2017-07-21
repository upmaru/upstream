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

  alias Blazay.Uploader.{
    Flow
  }

  require Logger

  # Client API

  def start_link(job) do
    GenServer.start_link(__MODULE__, job, name: via_tuple(job.name))
  end

  def init(job) do
    {:ok, status} = Status.start_link

    {:ok, %{
      job: job,
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

  # Server Callbacks

  def handle_cast(:upload, state) do
    Task.Supervisor.start_child TaskSupervisor, fn ->
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
        {:error, reason} -> 
          {:error, reason} 
      end
    end

    new_state = Map.merge(state, %{current_state: :uploading})

    {:noreply, new_state}
  end

  def handle_call(:finish, _from, state) do
    new_state = Map.merge(state, %{current_state: :finished})
    send state.job.owner, {:finished, state.job.name}
    {:reply, :finished, new_state}
  end

  def handle_call(:stop, _from, state) do
    Status.stop(state.status)

    case state.current_state do
      the_state when the_state in [:started, :uploading] ->
        Logger.info "-----> Cancelling #{state.job.name}"
        {:stop, :shutdown, state}
      :finished ->
        Logger.info "-----> #{state.job.name} #{Atom.to_string(state.current_state)}"
        {:stop, :shutdown, state}
    end
  end

  def terminate(reason, state) do
    Logger.info "-----> Shutting down #{state.job.name}"
    reason
  end

  # Private functions

  defp via_tuple(job_name) do
    {:via, Registry, {Blazay.Uploader.Registry, job_name}}
  end
end
