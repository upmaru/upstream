defmodule Upstream.B2.LargeFile do
  @moduledoc """
  Public facing api for B2 LargeFile
  """
  alias Upstream.B2.Account.Authorization

  alias Upstream.B2.LargeFile.{
    Start,
    Cancel,
    Finish,
    Unfinished
  }

  @callback start(Authorization.t(), binary(), map()) :: {:error, struct} | {:ok, struct}
  @callback finish(Authorization.t(), binary(), list()) :: {:error, struct} | {:ok, struct}
  @callback cancel(Authorization.t(), binary()) :: {:error, struct} | {:ok, struct}
  @callback unfinished(Authorization.t()) :: {:error, struct} | {:ok, struct}

  @doc """
  `Upstream.B2.LargeFile.start/1` Starts the uploading of the large_file on b2
  """
  @spec start(Authorization.t(), String.t()) :: {:ok | :error, %Start{} | struct}
  def start(auth, file_name) do
    Start.call(auth, body: file_name)
  end

  @spec start(Authorization.t(), any(), any()) :: {:error, struct} | {:ok, struct}
  def start(auth, file_name, metadata) do
    Start.call(auth, body: %{file_name: file_name, file_info: metadata})
  end

  @spec finish(Authorization.t(), any(), any()) :: {:error, struct} | {:ok, struct}
  def finish(auth, file_id, sha1_array) do
    Finish.call(
      auth,
      body: [
        file_id: file_id,
        sha1_array: sha1_array
      ]
    )
  end

  @spec cancel(Authorization.t(), String.t()) :: {:ok | :error, %Cancel{} | struct}
  def cancel(auth, file_id), do: Cancel.call(auth, body: file_id)

  @spec unfinished(Authorization.t()) :: {:error, struct} | {:ok, struct}
  def unfinished(auth), do: Unfinished.call(auth)
end
