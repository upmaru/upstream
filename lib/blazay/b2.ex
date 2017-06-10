defmodule Blazay.B2 do
  defmacro __using__(_) do
    quote do
      alias Blazay.Request
      alias Blazay.B2.{
        Url, Account
      }

      @behaviour unquote(__MODULE__)

      @spec call(Keyword.t) :: {:ok | :error, %__MODULE__{} | struct}
      def call(options \\ []) do
        url_option    = Keyword.get(options, :url, nil)
        header_option = Keyword.get(options, :header, nil)
        body_option   = Keyword.get(options, :body, nil)

        Request.post(
          %__MODULE__{},
          __MODULE__.url(url_option),
          (__MODULE__.body(body_option) |> process_body),
          __MODULE__.header(header_option)
        )
      end

      def header(nil), do: header()
      def header, do: [Account.authorization_header]

      def body(nil), do: %{}

      defp process_body(%{} = body), do: Poison.encode!(body)
      defp process_body(body), do: body

      defoverridable [header: 0, body: 1]
    end
  end

  @callback url(nil | String.t | map | none) :: String.t
  @callback body(nil | String.t | map | any) :: map | any
  @callback header(nil | String.t | map | none) :: List.t
end