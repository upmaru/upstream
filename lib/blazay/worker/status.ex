defmodule Blazay.Worker.Status do
  @moduledoc """
  used to track the status of the upload process
  """
  defstruct [:uploaded, :progress]

  @type t :: %__MODULE__{
    uploaded: List.t,
    progress: map
  }

  # TODO need to track sha1 array order correctly
  def start_link do
    Agent.start_link(fn ->
      %__MODULE__{
        uploaded: [],
        progress: %{}
      }
    end)
  end

  def upload_complete?(pid) do
    progress_count(pid) == uploaded_count(pid)
  end

  def uploaded_count(pid) do
    Agent.get pid, fn reports ->
      Enum.count(reports.uploaded)
    end
  end

  def progress_count(pid) do
    Agent.get pid, fn reports ->
      Enum.count(reports.progress)
    end
  end

  def stop(pid), do: Agent.stop(pid)

  def thread_count(pid) do
    Agent.get pid, fn reports ->
      Enum.count(reports.progress)
    end
  end

  def bytes_transferred(pid) do
    Agent.get pid, fn reports ->
      reports.progress
      |> Enum.map(fn {_, transferred} ->
        transferred
      end)
      |> Enum.sum
    end
  end

  def add_uploaded({index, checksum}, pid) do
    Agent.get_and_update pid, fn reports ->
      new_uploaded = List.insert_at(reports.uploaded, index, checksum)

      {reports, Map.put(reports, :uploaded, new_uploaded)}
    end

    {index, checksum}
  end

  def get_uploaded_sha1(pid) do
    Agent.get pid, fn reports -> reports.uploaded end
  end

  def add_bytes_out(bytes, pid, thread) do
    Agent.get_and_update pid, fn reports ->
      {_old, new_progress} =
        Map.get_and_update reports.progress, "#{thread.checksum}", fn transferred ->
          {transferred, (transferred || 0) + bytes}
        end

      {reports, Map.put(reports, :progress, new_progress)}
    end
  end
end
