defmodule Blazay.Uploader do
  alias Blazay.Uploader.{
    Supervisor, 
    LargeFile
  }

  def upload_large_file!(file_path) do
    file_path 
    |> start(:large_file)
    |> upload!(:large_file)
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

  defp start(file_path, :large_file) do
    {:ok, pid} = Supervisor.start_large_file(file_path, name(file_path))

    {:ok, pid, file_path}
  end

  defp upload!({:ok, _, file_path}, :large_file) do
    file_path |> name |> LargeFile.upload
  end

  defp name(file_path) do
    {:via, Registry, {Blazay.Uploader.Registry, file_path}}
  end
end