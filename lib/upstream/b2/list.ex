defmodule Upstream.B2.List do
  @moduledoc """
  For listing existing files, buckets
  """

  alias Upstream.B2.Account.Authorization
  alias Upstream.B2.List.{
    FileNames
  }

  @spec by_file_name(Authorization.t(), any()) :: {:error, struct} | {:ok, struct}
  def by_file_name(auth, file_name) do
    FileNames.call(auth, body: file_name)
  end
end
