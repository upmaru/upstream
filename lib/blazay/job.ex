defmodule Blazay.Job do
  @moduledoc """
  Gathers all the data required to start the upload process.

  It will also automaticall select which uploader to use, the normal
  file uploader or large_file uploader.
  """

  defstruct [:entry, :threads]

  @type t :: %__MODULE__{
    entry: Entry.LargeFile.t,
    threads: List.t,
  }

  alias Blazay.{
    Uploader,
    Entry,
    B2
  }

  alias Uploader.TaskSupervisor

  def create(file_path) do
    entry = Entry.prepare(file_path)
    threads = Enum.map(prepare_thread(entry, started.file_id), &Task.await/1)

    job = %__MODULE__{
      entry: entry,
      threads: threads
    }

    if entry.threads == 1 do
      Uploader.Supervisor.start_file(job)
    else
      Uploader.Supervisor.start_large_file(job)
    end
  end

  defp prepare_thread(entry, file_id) do
    for chunk <- entry.stream do
      Task.Supervisor.async(TaskSupervisor, fn -> 
        __MODULE__.Thread.prepare(chunk, file_id)
      end)
    end
  end
end
