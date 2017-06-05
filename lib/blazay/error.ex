defmodule Blazay.Error do
  defstruct status: nil, code: nil, message: nil

  @type t :: %__MODULE__{
    status: integer,
    code: String.t,
    message: String.t
  }

  @spec render(String.t) :: {:error, %__MODULE__{}}
  def render(body) when is_binary(body) do
    response = Poison.decode!(body)

    {:error, %__MODULE__{
      status: response["status"],
      code: response["code"],
      message: response["message"]
    }}
  end
end