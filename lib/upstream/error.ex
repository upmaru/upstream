defmodule Upstream.Error do
  @moduledoc """
  for handling error from the b2 server calls
  """

  defstruct status: nil, code: nil, message: nil

  @type t :: %__MODULE__{
          status: integer,
          code: String.t(),
          message: String.t()
        }
end
