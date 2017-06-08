defmodule Blazay.Upload do
  alias Blazay.Upload.{
    PartUrl,
    Part
  }

  def part_url(file_id), do: PartUrl.call(file_id)
end