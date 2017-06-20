defmodule Blazay.Job do
  alias Blazay.{Entry, Job}

  def create(file_path) do
    file_path
    |> Entry.LargeFile.prepare
    |> Job.B2.prepare
  end
end
