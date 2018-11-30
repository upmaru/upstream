defmodule Upstream.B2.Upload do
  @moduledoc """
  Public api for B2.Upload
  """
  alias Upstream.B2.Upload.{
    PartUrl,
    Part,
    Url,
    File
  }

  def part_url(auth, file_id), do: PartUrl.call(auth, body: file_id)

  def part(auth, url, header, body) do
    Part.call(
      auth,
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

  @spec url(atom()) ::
          {:error, %{optional(:__struct__) => atom(), optional(atom()) => any()}}
          | {:ok, %{:__struct__ => atom(), optional(atom()) => any()}}
  def url(auth), do: Url.call(auth)

  @spec file(Upstream.B2.Account.Authorization.t(), any(), any(), any()) :: {:error, struct} | {:ok, struct}
  def file(auth, url, header, body) do
    File.call(
      auth,
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
