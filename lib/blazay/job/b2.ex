defmodule Blazay.Job.B2 do
  defstruct [:entry, :job, :threads]

  alias Blazay.{B2, Job}
  alias Blazay.Uploader.TaskSupervisor


  @type t :: %__MODULE__{
    entry: Entry.LargeFile.t,
    job: B2.Start.t,
    threads: List.t
  }

  def prepare(entry) do
    {:ok, started} = B2.LargeFile.start(entry.name)
    threads = prepare_thread(entry, started.file_id)
              |> Enum.map(&Task.await/1)

    %__MODULE__{
      entry: entry,
      job: started,
      threads: threads
    }
  end

  defp prepare_thread(entry, file_id) do
    for chunk <- entry.stream do
      Task.Supervisor.async(TaskSupervisor, fn -> 
        Job.B2.Thread.prepare(chunk, file_id)
      end)
    end
  end
end