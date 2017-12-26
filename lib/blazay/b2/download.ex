defmodule Blazay.B2.Download do
  @moduledoc """
  Handles download requests to the b2 api
  """

  alias Blazay.B2.Download.{
    Authorization
  }

  alias Blazay.B2.Account

  def authorize(prefix, duration \\ 3600) do
    Authorization.call(
      body: [
        prefix: prefix, duration: duration
      ]
    )
  end

  def url(file_name, authorization) do
    file_url = Enum.join(
      [Account.download_url, "file", Blazay.config(:bucket_name), file_name], "/"
    )

    file_url <> "?Authorization=" <> authorization
  end
end
