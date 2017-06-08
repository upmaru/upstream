defmodule Blazay.Request do
  defmodule Caller do
    defmacro __using__(_) do
      quote do
        alias Blazay.{Url, Account, Request}
        @behaviour unquote(__MODULE__)

        @spec call(nil | String.t | map) :: {:ok | :error, %__MODULE__{} | struct}
        def call(params) do
          %__MODULE__{}
          |> Request.get(
            __MODULE__.url(), 
            __MODULE__.header(), 
            __MODULE__.params(params)
          )
        end

        def header, do: [Account.authorization_header]

        defoverridable [header: 0]
      end
    end

    @callback url :: String.t
    @callback header :: List.t
    @callback params(nil | String.t | map) :: Keyword.t
  end

  alias Blazay.Error

  @spec get(struct, String.t, List.t, Keyword.t) :: {:ok | :error, struct | %Error{}}
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