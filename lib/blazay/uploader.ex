defmodule Blazay.Uploader do
  alias Blazay.Uploader.Supervisor

  def start(:large_file, file_path) do
    Supervisor.start_large_file(file_path)
  end
end