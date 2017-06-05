defmodule Blazay.Response.Authorization do
  defstruct account_id: nil, authorization_token: nil, api_url: nil, download_url: nil, 
            recommended_part_size: nil, absolute_minimum_part_size: nil

  @type t :: %__MODULE__{
    account_id: String.t,
    authorization_token: String.t,
    api_url: String.t,
    download_url: String.t,
    recommended_part_size: integer,
    absolute_minimum_part_size: integer
  }
end