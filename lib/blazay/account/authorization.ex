defmodule Blazay.Account.Authorization do
  use Blazay.Request
  @behaviour Blazay.Request

  defstruct [
    :account_id, 
    :authorization_token, 
    :api_url, 
    :download_url,
    :recommended_part_size,
    :absolute_minimum_part_size
  ]

  @type t :: %__MODULE__{
    account_id: String.t,
    authorization_token: String.t,
    api_url: String.t,
    download_url: String.t,
    recommended_part_size: integer,
    absolute_minimum_part_size: integer
  }
  @doc """
  Authorize#call function will make a call to the api and authorize based on the
  account_id, and application_key passed in from the config.

  config :blazay, Blazay, 
    account_id: <whatever account_id>,
    application_key: <whatever application_key>
  """
  @spec call :: {:ok | :error, %__MODULE__{} | %Error{}}
  def call, do: call(nil)

  @spec call(any) :: {:ok | :error, %__MODULE__{} | %Error{}}
  def call(_) do
    url = Url.generate(:authorize_account)

    case get(url, header(), params: []) do
      {:ok, %{status_code: 200, body: body}} ->
        body |> render()
      {:ok, %{status_code: _, body: body}} ->
        body |> Error.render()
    end
  end

  defp header do
    encoded = "Basic " <> Base.encode64(
      Blazay.config(:account_id) <> ":" <> Blazay.config(:application_key)
    )
    
    [{"Authorization", encoded}]
  end

  defp render(body) do
    response = Poison.decode!(body)

    {:ok, %__MODULE__{
      account_id: response["accountId"],
      authorization_token: response["authorizationToken"],
      api_url: response["apiUrl"],
      download_url: response["downloadUrl"],
      recommended_part_size: response["recommendedPartSize"],
      absolute_minimum_part_size: response["absoluteMinimumPartSize"]
    }}
  end
end