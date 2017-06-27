defmodule Blazay.Uploader do
  alias Blazay.Uploader.{
    Supervisor, 
    LargeFile
  }

  def start_large_file(file_path) do
    Supervisor.start_large_file(file_path, name(file_path))
  end

  def large_file(file_path, :entry) do
    file_path |> name |> LargeFile.entry
  end

  def large_file(file_path, :threads) do
    file_path |> name |> LargeFile.threads
  end 

  def large_file(file_path, :progress) do 
    file_path |> name |> LargeFile.progress
  end

  def cancel_large_file!(file_path) do
    file_path |> name |> LargeFile.cancel
  end

  def upload_large_file!(file_path) do 
    file_path |> name |> LargeFile.upload
  end

  defp name(file_path) do
    {:via, Registry, {Blazay.Uploader.Registry, file_path}}
  end
end