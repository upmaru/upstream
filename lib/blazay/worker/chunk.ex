defmodule Blazay.Worker.Chunk do
  @moduledoc """
  Handles uploading of chunks (pieces from the client)
  """
  use GenServer

  alias Blazay.B2.{
    Upload
  }

  # Client API

  def start_link(job, file_id, index) do
    GenServer.start_link(
      __MODULE__,
      %{job: job, file_id: file_id, index: index},
      name: via_tuple("#{file_id}_#{index}")
    )
  end

  def finish(job_name) do
    GenServer.call(via_tuple(job_name), :finish)
  end

  # Server Callbacks

  def init(chunk_data) do
    {:ok, status} = Status.start_link

    {:ok, %{
      job: chunk_data.job,
      file_id: chunk_data.file_id,
      index: chunk_data.index,
      status: status,
      current_state: :started
    }}
  end

  def handle_cast(:upload, from, state) do
    Task.Supervisor.start_child TaskSupervisor, fn ->
      {:ok, checksum} = Checksum.start_link
      {:ok, part_url} = Upload.part_url(state.file_id)

      index = state.index

      header = %{
        authorization: part_url.authorization_token,
        x_bz_part_number: (index + 1),
        content_length: state.job.content_length + 40,
        x_bz_content_sha1: "hex_digits_at_end"
      }

      body = Flow.generate(
        state.job.stream, index, checksum, state.status
      )


      case Upload.part(part_url.upload_url, header, body) do
        {:ok, part} ->
          Checksum.stop(checksum)
          __MODULE__.finish(state.job.name)
          __MODULE__.stop(state.job.name)
      end
    end

    new_state = Map.merge(state, %{current_state: :uploading})

    {:noreply, new_state}
  end

  def handle_call(:finish, from, state) do
    
  end

  # Private Functions

  defp via_tuple(file_id_index) do
    {:via, Registry, {Blazay.Uploader.Registry, file_id_index}}
  end
end
