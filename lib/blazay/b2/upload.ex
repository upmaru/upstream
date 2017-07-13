defmodule Blazay.B2.Upload do
  alias Blazay.B2.Upload.{
    PartUrl,
    Part,
    Url,
    File
  }

  def part_url(file_id), do: PartUrl.call(body: file_id)
  def part(url, header, body) do
    Part.call(
      url: url,
      header: header,
      body: body,
      options: [
        timeout: :infinity,
        recv_timeout: :infinity,
        connect_timeout: :infinity
      ]
    )
  end

  def url, do: Url.call

  def file(url, header, body) do
    File.call(
      url: url,
      header: header,
      body: body,
      options: [
        timeout: :infinity,
        recv_timeout: :infinity,
        connect_timeout: :infinity
      ]
    )
  end
end