defmodule Blazay.Uploader do
  @moduledoc """
  Uploader public api that allows us to query the uploader
  for detail and make calls to start the upload process.
  """

  alias Blazay.Job

  alias __MODULE__.Supervisor

  def upload!(file_path) do
    file_path
    |> Job.create
    |> Supervisor.start_job
    |> Supervisor.upload
  end
end
