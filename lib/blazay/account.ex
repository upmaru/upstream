defmodule Blazay.Account do
  import HTTPoison, only: [get: 3]
  alias Blazay.Response.Authorization

  alias Blazay.Url

  @doc """
  authorize function will make a call to the api and authorize based on the
  account_id, and application_key passed in from the config.

  config :blazay, Blazay, 
    account_id: <whatever account_id>,
    application_key: <whatever application_key>
  """

  @spec authorize :: %Authorization{}
  def authorize do
    url = Url.generate(:authorize_account)

    case get(url, authorization_header(), params: []) do
      {:ok, %{status_code: 200, body: body}} -> deserialize(body)
      {:error, error} -> error
    end
  end

  defp authorization_header do
    encoded = "Basic " <> Base.encode64(
      Blazay.config(:account_id) <> ":" <> Blazay.config(:application_key)
    )
    
    [{"Authorization", encoded}]
  end

  defp deserialize(body) do
    {:ok, response} = Poison.decode(body)

    %Authorization{
      account_id: response["accountId"],
      authorization_token: response["authorizationToken"],
      api_url: response["apiUrl"],
      download_url: response["downloadUrl"],
      recommended_part_size: response["recommendedPartSize"],
      absolute_minimum_part_size: response["absoluteMinimumPartSize"]
    }
  end
end