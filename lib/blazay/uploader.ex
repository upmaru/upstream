defmodule Blazay.Uploader do
  alias Blazay.Uploader.{
    Supervisor, 
    LargeFile
  }

  def start(file_path, :large_file) do
    Supervisor.start_large_file(file_path)
  end

  def entry(pid, :large_file),  do: pid |> LargeFile.get(:entry)
  def job(pid, :large_file),    do: pid |> LargeFile.get(:job)
  def cancel(pid, :large_file), do: pid |> LargeFile.cancel
  def upload(pid, :large_file), do: pid |> Largefile.upload
end