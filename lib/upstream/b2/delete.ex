defmodule Upstream.B2.Delete do
  @moduledoc """
  Handles Deletion of Files
  """

  alias Upstream.B2.Account.Authorization

  alias Upstream.B2.Delete.{
    FileVersion
  }

  @spec file_version(Authorization.t(), any(), any()) :: {:error, struct} | {:ok, struct}
  def file_version(auth, file_name, file_id) do
    FileVersion.call(
      auth,
      body: [
        file_name: file_name,
        file_id: file_id
      ]
    )
  end
end
