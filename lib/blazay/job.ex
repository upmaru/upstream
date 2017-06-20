defmodule Blazay.Job do
  alias Blazay.Job.{LargeFile, B2}

  def create(:large_file, file_path) do
    LargeFile.prepare(file_path)
  end

  def create(:b2, job) do
    B2.prepare(job)
  end
end
