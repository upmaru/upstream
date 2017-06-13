defmodule Blazay.Job.LargeFile.B2 do
  defstruct [:job, :threads]

  @type t :: %__MODULE__{
    job: %Start{},
    threads: List.t
  }
end