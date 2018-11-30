defmodule Upstream.B2.Account do
  @moduledoc """
  Authorizes the b2 account and start agent so we can access the data
  without making another authorize_account call.
  """
  use Agent

  alias Upstream.B2.Account.Authorization

  require Logger

  @spec start_link(any()) :: {:error, any()} | {:ok, pid()}
  def start_link(_args) do
    case Application.fetch_env(:upstream, :storage) do
      {:ok, _config} ->
        Agent.start_link(&authorize/0, name: __MODULE__)

      :error ->
        Logger.info("[Upstream] No config set, your Uploaders won't work. (╯°□°）╯︵ ┻━┻")
        Agent.start_link(fn -> {:error, :no_config_set} end, name: __MODULE__)
    end
  end

  @spec re_authorize() :: :ok
  def re_authorize do
    Agent.update(__MODULE__, fn _authorization -> authorize() end)
  end

  @spec authorization :: %Authorization{}
  @doc """
  Returns the %Authorization{} data struct that will allow you to retrieve
  the data required.
  """
  def authorization do
    Agent.get(__MODULE__, &ensure_correct_auth_data/1)
  end

  defp authorize do
    Logger.info("[Upstream] Authorizing B2 account...")

    case Authorization.call() do
      {:ok, authorization} -> authorization
      {:error, error} -> raise error.message
    end
  end

  defp ensure_correct_auth_data(auth) do
    case auth do
      %Authorization{} ->
        auth

      {:error, :no_config_set} ->
        raise "No Configuration Set"
    end
  end
end
