defmodule Blazay.Uploader do
  @moduledoc """
  Uploader public api that allows us to query the uploader
  for detail and make calls to start the upload process.
  """

  alias Blazay.Job

  def start(file_path) do
    job = Job.create(file_path)
  end
end
