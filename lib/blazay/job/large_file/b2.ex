defmodule Blazay.Job.LargeFile.B2 do
  defstruct [:job, :threads]

  alias Blazay.B2.LargeFile.Start

  @type t :: %__MODULE__{
    job: %Start{},
    threads: List.t
  }
end