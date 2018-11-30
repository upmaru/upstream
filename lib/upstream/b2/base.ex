defmodule Upstream.B2.Base do
  @moduledoc """
  Base B2 module for using in the api call definitions

  simply call `use Upstream.B2` in the module and define the url, header, body
  and use the module to make the calls.
  """
  alias Upstream.Request

  defmacro __using__(_) do
    quote do
      alias Upstream.B2.{
        Url,
        Account
      }

      alias Account.Authorization

      @behaviour unquote(__MODULE__)

      @spec call(Authorization.t(), Keyword.t()) :: {:ok | :error, %__MODULE__{} | struct}
      def call(auth \\ %Authorization{}, options \\ []) do
        url_option = Keyword.get(options, :url, nil)
        header_option = Keyword.get(options, :header, nil)
        body_option = Keyword.get(options, :body, nil)
        request_options = Keyword.get(options, :options, [])

        Request.post(
          %__MODULE__{},
          url(auth, url_option),
          process_body(body(body_option)),
          header(auth, header_option),
          request_options
        )
      end

      def header(auth, nil), do: [{"Authorization", auth.authorization_token}]

      def body(nil), do: %{}

      defp process_body(%{} = body), do: Jason.encode!(body)
      defp process_body(body), do: body

      defoverridable header: 2, body: 1
    end
  end

  alias Upstream.B2.Account.Authorization

  @callback body(nil | String.t() | map | any) :: map | any
  @callback url(Authorization.t(), nil | String.t() | map | none) :: String.t()
  @callback header(Authorization.t(), nil | String.t() | map | none) :: List.t()
end
