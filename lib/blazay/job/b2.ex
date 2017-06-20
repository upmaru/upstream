defmodule Blazay.Job.B2 do
  defstruct [:file, :job, :threads]

  alias Blazay.{B2, Job}
  alias Blazay.Uploader.TaskSupervisor


  @type t :: %__MODULE__{
    file: LargeFile.t,
    job: Start.t,
    threads: List.t
  }

  def prepare(job, :large_file) do
    {:ok, started} = B2.LargeFile.start(file_path)

    tasks = for _n <- 1..job.threads do
      Task.Supervisor.async(TaskSupervisor, fn -> 
        B2.Upload.part_url(started.file_id)
      end)
    end

    %__MODULE__{
      file: job,
      job: started,
      threads: prepare_thread(job)
    }
  end


  def prepare_thread(job) do
    job.stream |> Enum.map(&Thread.prepare/1)
  end
end