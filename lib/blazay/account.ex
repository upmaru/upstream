defmodule Blazay.Account do
  import HTTPoison, only: [get: 3]
  alias Blazay.{Url, Response}

  @doc """
  authorize function will make a call to the api and authorize based on the
  account_id, and application_key passed in from the config.

  config :blazay, Blazay, 
    account_id: <whatever account_id>,
    application_key: <whatever application_key>
  """

  @spec authorize :: {:ok | :error, struct}
  def authorize do
    url = Url.generate(:authorize_account)

    case get(url, authorization_header(), params: []) do
      {:ok, %{status_code: 200, body: body}} ->
        body |> Response.deserialize(:authorization)
      {:ok, %{status_code: _, body: body}} ->
        body |> Response.deserialize(:error)
    end
  end

  defp authorization_header do
    encoded = "Basic " <> Base.encode64(
      Blazay.config(:account_id) <> ":" <> Blazay.config(:application_key)
    )
    
    [{"Authorization", encoded}]
  end
end