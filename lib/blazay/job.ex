defmodule Blazay.Job do
  alias Blazay.Job.LargeFile

  def create(:large_file, file_path) do
    LargeFile.prepare(file_path)
  end
end
