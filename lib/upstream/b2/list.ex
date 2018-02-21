defmodule Upstream.B2.List do
  @moduledoc """
  For listing existing files, buckets
  """

  alias Upstream.B2.List.{
    FileNames
  }

  def by_file_name(file_name) do
    FileNames.call(body: file_name)
  end
end
