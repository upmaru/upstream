defmodule Blazay.Account do
  import HTTPoison, only: [get: 3]
  alias Blazay.Url

  def authorize do
    url = Url.generate(:authorize_account)

    case get(url, authorization_header(), params: []) do
      {:ok, response} -> response
      {:error, error} -> error
    end
  end

  defp authorization_header do
    encoded = "Basic " <> Base.encode64(
      Blazay.config(:account_id) <> ":" <> Blazay.config(:application_key)
    )
    
    [{"Authorization", encoded}]
  end
end