defmodule Blazay.Request do
  defmacro __using__(_) do
    quote do
      import HTTPoison, only: [get: 3]
      alias Blazay.{Url, Error, Account}
    end
  end
  
  @callback call(nil | String.t) :: {atom, struct}
end