defmodule Blazay.Request do
  defmodule Caller do
    defmacro __using__(_) do
      quote do
        alias Blazay.{Url, Account, Request}
        @behaviour unquote(__MODULE__)

        @spec call(atom, nil | String.t | map, Keyword.t) :: {:ok | :error, %__MODULE__{} | struct}
        def get(params \\ nil, options \\ []) do
          url_option    = Keyword.get(options, :url, nil)
          header_option = Keyword.get(options, :header, nil)

          %__MODULE__{}
          |> Request.get(
            __MODULE__.url(url_option),
            __MODULE__.header(header_option), 
            __MODULE__.params(params)
          )
        end

        def post(body, options \\ []) do
          url_option    = Keyword.get(options, :url, nil)
          header_option = Keyword.get(options, :header, nil)

          %__MODULE__{}
          |> Request.post(
            __MODULE__.url(url_option), body,
            __MODULE__.header(header_option), 
          )
        end

        def header(nil), do: header()
        def url(nil), do: url()
        def params(nil), do: [params: []]
        
        def header, do: [Account.authorization_header]

        defoverridable [header: 0, header: 1, url: 1, params: 1]
      end
    end

    @callback url(nil | String.t | map | none) :: String.t
    @callback header(nil | String.t | map | none) :: List.t
    @callback params(nil | String.t | map) :: Keyword.t
  end

  alias Blazay.Error

  @spec get(struct, String.t, List.t, Keyword.t) :: {:ok | :error, %Error{} | struct}
  def get(caller_struct, url, header, params) do
    case HTTPoison.get(url, header, params) do
      {:ok, %{status_code: 200, body: body}} ->
        {:ok, struct(caller_struct, process_response(body))}
      {:ok, %{status_code: _, body: body}} ->
        {:error, struct(Error, process_response(body))}
    end
  end

  def post(caller_struct, url, body, header) do
    case HTTPoison.post(url, body, header) do
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