defmodule Blazay.Response do
  alias __MODULE__.{Error, Authorization}

  @spec deserialize(String.t, atom) :: {atom, struct}
  def deserialize(body, :error) when is_binary(body) do
    response = Poison.decode!(body)

    {:error, %Error{
      status: response["status"],
      code: response["code"],
      message: response["message"]
    }}
  end

  def deserialize(body, :authorization) when is_binary(body) do
    response = Poison.decode!(body)

    {:ok, %Authorization{
      account_id: response["accountId"],
      authorization_token: response["authorizationToken"],
      api_url: response["apiUrl"],
      download_url: response["downloadUrl"],
      recommended_part_size: response["recommendedPartSize"],
      absolute_minimum_part_size: response["absoluteMinimumPartSize"]
    }}
  end
end