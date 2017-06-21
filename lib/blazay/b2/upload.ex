defmodule Blazay.B2.Upload do
  alias Blazay.B2.Upload.{
    PartUrl,
    Part
  }

  def part_url(file_id), do: PartUrl.call(body: file_id)
  def part(url, header, body) do 
    Part.call(url: url, header: header, body: body)
  end
end