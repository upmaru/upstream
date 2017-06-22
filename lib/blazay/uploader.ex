defmodule Blazay.Uploader do
  alias Blazay.Uploader.{
    Supervisor, 
    LargeFile
  }

  def start_large_file(file_path) do
    Supervisor.start_large_file(file_path)
  end

  def large_file(pid, :entry),    do: pid |> LargeFile.get(:entry)
  def large_file(pid, :threads),  do: pid |> LargeFile.get(:threads)
  def large_file(pid, :progress), do: pid |> LargeFile.progress

  def cancel_large_file!(pid),  do: pid |> LargeFile.cancel
  def upload_large_file!(pid),  do: pid |> LargeFile.upload
end