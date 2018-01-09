defmodule Upstream do
  use Application
  @moduledoc """
  Upstream is a utility for working with file upload.
  It specifically integrates with backblaze b2 object store service.
  """

  require Logger

  def start(_type, _args) do
    Upstream.Supervisor.start_link()
  end

  @doc """
  Upstream.base_api returns the base api string

  ## Examples

    iex> Upstream.base_api
    "https://api.backblazeb2.com"
  """
  @b2_base_api ~S(https://api.backblazeb2.com)
  def base_api, do: @b2_base_api

  def config, do: Application.get_env(:upstream, Upstream)

  @concurrency 2
  def concurrency, do: config(:concurrency) || @concurrency

  @file_param "file"
  def file_param, do: config(:file_param) || @file_param

  @doc """
  Upstream.config/1 help you get to your config

  ## Examples

    iex> Upstream.config(:account_id)
    Keyword.fetch!(Upstream.config, :account_id)
  """
  def config(key), do: Keyword.get(config(), key, nil)

  def set_config(config) do
    Logger.info "[Upstream] -----> Setting config and restarting Upstream"
    with :ok <- Application.put_env(:upstream, Upstream, config),
         :ok <- Upstream.Supervisor.stop(),
         do: Upstream.Supervisor.start_link()
  end
end
