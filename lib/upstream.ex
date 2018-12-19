defmodule Upstream do
  @moduledoc """
  Upstream is a utility for working with file upload.
  It specifically integrates with backblaze b2 object store service.
  """

  require Logger

  @doc """
  Upstream.base_api returns the base api string

  ## Examples

    iex> Upstream.base_api
    "https://api.backblazeb2.com"
  """
  alias Upstream.B2.Account

  @b2_base_api ~S(https://api.backblazeb2.com)
  def base_api, do: @b2_base_api

  @spec config() :: any()
  def config, do: Application.get_env(:upstream, Upstream) || []
  @spec storage() :: any()
  def storage, do: Application.get_env(:upstream, :storage) || []

  @file_param "file"
  @spec file_param() :: any()
  def file_param, do: config(:file_param) || @file_param

  @spec config(atom()) :: any()
  def config(key), do: Keyword.get(config(), key, nil)

  @spec storage(atom()) :: any()
  def storage(key), do: Keyword.get(storage(), key, nil)

  @spec set_config(any()) :: {:ok, Upstream.B2.Account.Authorization.t()}
  def set_config(config) do
    Logger.info("[Upstream] -----> Setting config and re authorizing")
    Application.put_env(:upstream, :storage, config)
    Account.re_authorize()

    {:ok, Account.authorization()}
  end
end
