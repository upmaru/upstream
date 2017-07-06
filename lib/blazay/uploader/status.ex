defmodule Blazay.Uploader.Status do
  @moduledoc """
  used to track the status of the upload process
  """
  defstruct [:sha1_array, :progress]

  @type t :: %__MODULE__{
    sha1_array: map,
    progress: map
  }

  # TODO need to track sha1 array order correctly
  def start_link do
    Agent.start_link(fn ->
      %__MODULE__{
        sha1_array: %{},
        progress: %{}
      } 
    end)
  end

  def stop(pid), do: Agent.stop(pid)

  def get(pid) do
    Agent.get pid, fn reports ->
      reports.progress
      |> Enum.map(fn {_, status} -> (status || 0) end)
      |> Enum.sum
      |> Float.round(2)
    end
  end

  def get_sha1_array(pid) do
    Agent.get pid, fn reports ->
      Map.keys(reports)
    end
  end

  def thread_count(pid) do
    Agent.get pid, fn reports ->
      Enum.count(reports)
    end
  end

  def add_bytes_out(bytes, pid, thread) do
    Agent.get_and_update pid, fn reports ->
      Map.get_and_update reports, "#{thread.checksum}", fn status ->
        {status, (status || 0) + (bytes / thread.content_length * 100.0)}
      end
    end
  end
end
