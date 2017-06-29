defmodule Blazay.Job do
  defstruct [:entry, :file_id, :threads]

  @type t :: %__MODULE__{
    entry: Entry.LargeFile.t,
    file_id: String.t,
    threads: List.t,
  }

  alias Blazay.{
    Uploader,
    Entry, 
    B2
  }
  
  alias Uploader.TaskSupervisor
  
  def create(file_path) do
    file_path
    |> Entry.LargeFile.prepare
    |> prepare
  end

  defp prepare(entry) do
    {:ok, started} = B2.LargeFile.start(entry.name)

    threads = prepare_thread(entry, started.file_id)
              |> Enum.map(&Task.await/1)

    %__MODULE__{
      entry: entry,
      file_id: started.file_id,
      threads: threads
    }
  end

  defp prepare_thread(entry, file_id) do
    for chunk <- entry.stream do
      Task.Supervisor.async(TaskSupervisor, fn -> 
        __MODULE__.Thread.prepare(chunk, file_id)
      end)
    end
  end
end
