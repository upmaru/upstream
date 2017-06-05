defmodule Blazay.Response.Authorization do
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
end