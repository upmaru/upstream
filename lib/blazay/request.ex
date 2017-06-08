defmodule Blazay.Request do
  defmodule Caller do
    defmacro __using__(_) do
      quote do
        alias Blazay.{Url, Account}
        @behaviour unquote(__MODULE__)
      end
    end

    @callback call(nil | String.t) :: {:ok | :error, struct}
  end

  alias Blazay.Error

  @spec get(struct, String.t, List.t, Keyword.t) :: {:ok | :error, struct}
  def get(caller_struct, url, header, params) do
    case HTTPoison.get(url, header, params) do
      {:ok, %{status_code: 200, body: body}} ->
        {:ok, struct(caller_struct, process_response(body))}
      {:ok, %{status_code: _, body: body}} ->
        {:error, struct(Error, process_response(body))}
    end
  end

  defp process_response(body) do
    body 
    |> Poison.decode!
    |> Enum.map(fn({k, v}) -> 
      {String.to_atom(Macro.underscore(k)), v}
    end)
  end
end