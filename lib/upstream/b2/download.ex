defmodule Upstream.B2.Download do
  @moduledoc """
  Handles download requests to the b2 api
  """

  alias Upstream.B2.Download.{
    Authorization
  }

  alias Upstream.B2.Account

  @spec authorize(Account.Authorization.t(), any(), any()) :: {:error, struct} | {:ok, struct}
  def authorize(auth, prefix, duration \\ 3600) do
    Authorization.call(
      auth,
      body: [
        prefix: prefix,
        duration: duration
      ]
    )
  end

  @spec url(Account.Authorization.t(), any(), binary()) :: binary()
  def url(%Account.Authorization{download_url: download_url} = _auth, file_name, authorization) do
    file_url =
      Enum.join(
        [download_url, "file", Upstream.storage(:bucket_name), file_name],
        "/"
      )

    URI.encode(file_url) <> "?Authorization=" <> authorization
  end
end
