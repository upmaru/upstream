defmodule Blazay do
  use Application
  @moduledoc """
  Blazay is a utility for working with file upload.
  It specifically integrates with backblaze b2 object store service.
  """

  require Logger

  def start(_type, _args) do
    Blazay.Supervisor.start_link()
  end

  @doc """
  Blazay.base_api returns the base api string

  ## Examples

    iex> Blazay.base_api
    "https://api.backblazeb2.com"
  """
  @b2_base_api ~S(https://api.backblazeb2.com)
  def base_api, do: @b2_base_api

  def config, do: Application.get_env(:blazay, Blazay)

  @concurrency 2
  def concurrency, do: config(:concurrency) || @concurrency

  @file_param "file"
  def file_param, do: config(:file_param) || @file_param

  @doc """
  Blazay.config/1 help you get to your config

  ## Examples

    iex> Blazay.config(:account_id)
    Keyword.fetch!(Blazay.config, :account_id)
  """
  def config(key), do: Keyword.get(config(), key, nil)

  def set_config(config) do
    Logger.info "-----> Setting config and restarting Blazay"
    with :ok <- Application.put_env(:blazay, Blazay, config),
         :ok <- Blazay.Supervisor.stop(),
         do: Blazay.Supervisor.start_link()
  end
end
