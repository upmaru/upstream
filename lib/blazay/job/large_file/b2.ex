defmodule Blazay.Job.LargeFile.B2 do
  defstruct [:job, :threads]

  alias Blazay.B2.LargeFile
  alias Blazay.Job.LargeFile.B2.Thread

  @type t :: %__MODULE__{
    job: %Start{},
    threads: List.t
  }

  def prepare(file_path, stream) do
    {:ok, started} = LargeFile.start(file_path)

    %__MODULE__{
      job: started,
      threads: prepare_thread(stream)
    }
  end


  def prepare_thread(stream) do
    stream |> Enum.map(&Thread.prepare/1)
  end
end