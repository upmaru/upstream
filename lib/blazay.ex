defmodule Blazay do
  use Application
  @moduledoc """
  Documentation for Blazay.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Blazay.hello
      :world

  """
  def start(_type, _args) do
    Blazay.Supervisor.start_link()
  end

  @b2_base_api ~S(https://api.backblazeb2.com/b2api/v1)
  def base_api, do: @b2_base_api
  
  @config Application.get_env(:blazay, Blazay)
  def config, do: @config
  def config(key), do: Keyword.fetch!(config(), key)
end
