defmodule Upstream.B2.Base do
  @moduledoc """
  Base B2 module for using in the api call definitions

  simply call `use Upstream.B2` in the module and define the url, header, body
  and use the module to make the calls.
  """

  defmacro __using__(_) do
    quote do
      alias Upstream.Request

      alias Upstream.B2.{
        Url,
        Account
      }

      @behaviour unquote(__MODULE__)

      @spec call(Keyword.t()) :: {:ok | :error, %__MODULE__{} | struct}
      def call(options \\ []) do
        url_option = Keyword.get(options, :url, nil)
        header_option = Keyword.get(options, :header, nil)
        body_option = Keyword.get(options, :body, nil)
        request_options = Keyword.get(options, :options, [])

        Request.post(
          %__MODULE__{},
          url(url_option),
          process_body(body(body_option)),
          header(header_option),
          request_options
        )
      end

      def header(nil), do: header()
      def header, do: [Account.authorization_header()]

      def body(nil), do: %{}

      defp process_body(%{} = body), do: Poison.encode!(body)
      defp process_body(body), do: body

      defoverridable header: 0, body: 1
    end
  end

  @callback url(nil | String.t() | map | none) :: String.t()
  @callback body(nil | String.t() | map | any) :: map | any
  @callback header(nil | String.t() | map | none) :: List.t()
end
