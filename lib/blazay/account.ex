defmodule Blazay.Account do
  alias Blazay.Request.Authorize
  alias Blazay.Response.Authorization

  require Logger

  @doc """
  Authorizes the b2 account and start agent so we can access the data
  without making another authorize_account call.
  """
  def start_link do
    Agent.start_link(&authorize/0, name: __MODULE__)
  end

  @spec authorization :: %Authorization{}
  @doc """
  Returns the %Authorization{} data struct that will allow you to retrieve
  the data required.
  """
  def authorization do
    __MODULE__ |> Agent.get(fn authorization -> authorization end)
  end

  def authorization_header do
    token = authorization().authorization_token

    {"Authorization", token}
  end

  defp authorize do
    Logger.info "Authorizing B2 account..."

    case Authorize.call do
      {:ok, authorization} -> authorization
      {:error, error} -> raise error.message
    end
  end
end