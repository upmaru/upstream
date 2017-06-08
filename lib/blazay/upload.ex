defmodule Blazay.Upload do
  alias Blazay.Upload.{
    PartUrl,
    Part
  }

  def part_url(file_id), do: PartUrl.get(file_id)
  def part(body, ) do: Part.post(body)
end