defmodule Upstream.B2.Base do
  @moduledoc """
  Base B2 module for using in the api call definitions

  simply call `use Upstream.B2` in the module and define the url, header, body
  and use the module to make the calls.
  """
  alias Upstream.Request

  alias Upstream.B2.Account.Authorization

  @callback body(nil | String.t() | map | Keyword.t()) :: tuple | map
  @callback url(Authorization.t(), nil | String.t() | map | none) :: String.t()
  @callback header(Authorization.t(), nil | String.t() | map | none) :: List.t()

  defmacro __using__(_) do
    quote do
      alias Upstream.B2.{
        Url,
        Account
      }

      alias Account.Authorization

      @behaviour unquote(__MODULE__)

      @spec call(Authorization.t() | nil, Keyword.t()) :: {:ok | :error, %__MODULE__{} | struct}
      def call(auth, options \\ []) do
        url_option = Keyword.get(options, :url, nil)
        header_option = Keyword.get(options, :header, nil)
        body_option = Keyword.get(options, :body, nil)
        request_options = Keyword.get(options, :options, [])

        Request.post(
          %__MODULE__{},
          url(auth, url_option),
          body(body_option),
          header(auth, header_option),
          request_options
        )
      end

      def header(auth, nil), do: [{"Authorization", auth.authorization_token}]

      def body(nil), do: %{}

      defoverridable header: 2, body: 1
    end
  end
end
