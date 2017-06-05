defmodule Blazay.Response.Error do
  defstruct status: nil, code: nil, message: nil

  @type t :: %__MODULE__{
    status: integer,
    code: String.t,
    message: String.t
  }
end