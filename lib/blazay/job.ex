defmodule Blazay.Job do
  alias Blazay.{Entry, Job}
  alias Blazay.Job.B2

  def create(file_path) do
    file_path
    |> Entry.LargeFile.prepare
    |> Job.B2.prepare
  end
end
