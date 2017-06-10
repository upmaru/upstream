defmodule Blazay.Job do
  def upload(file_name) do
    Blazay.Job.LargeFile.add(file_name)
  end
end
