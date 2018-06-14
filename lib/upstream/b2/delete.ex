defmodule Upstream.B2.Delete do
  alias Upstream.B2.Delete.{
    FileVersion
  }

  def file_version(file_name, file_id) do
    FileVersion.call(
      body: [
        file_name: file_name,
        file_id: file_id
      ]
    )
  end
end
