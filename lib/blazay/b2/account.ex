defmodule Blazay.B2.Account do
  @moduledoc """
  Authorizes the b2 account and start agent so we can access the data
  without making another authorize_account call.
  """
  alias Blazay.B2.Account.Authorization

  require Logger

  def start_link do
    Agent.start_link(&authorize/0, name: __MODULE__)
  end

  @spec authorization :: %Authorization{}
  @doc """
  Returns the %Authorization{} data struct that will allow you to retrieve
  the data required.
  """
  def authorization do
    Agent.get(__MODULE__, fn authorization -> authorization end)
  end

  def api_url, do: authorization().api_url
  def minimum_part_size, do: authorization().minimum_part_size
  def recommended_part_size, do: authorization().recommended_part_size
  def download_url, do: authorization().download_url

  def authorization_header do
    token = authorization().authorization_token

    {"Authorization", token}
  end

  defp authorize do
    Logger.info "Authorizing B2 account..."

    case Authorization.call do
      {:ok, authorization} -> authorization
      {:error, error} -> raise error.message
    end
  end
end
