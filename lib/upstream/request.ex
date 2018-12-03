defmodule Upstream.Request do
  @moduledoc """
  Request module for making and handling network request to b2
  """

  alias Upstream.Error

  @spec post(
          any(),
          binary(),
          any(),
          [{atom() | binary(), binary()}] | %{optional(binary()) => binary()},
          keyword()
        ) ::
          {:error, %{optional(:__struct__) => atom(), optional(atom()) => any()}}
          | {:ok, %{:__struct__ => atom(), optional(atom()) => any()}}
  def post(caller_struct, url, body, headers, options \\ []) do
    default_options = [
      timeout: :infinity,
      recv_timeout: :infinity,
      connect_timeout: :infinity
    ]

    merged_options = Keyword.merge(default_options, options)

    case HTTPoison.post(url, process_request_body(body), headers, merged_options) do
      {:ok, response = %HTTPoison.AsyncResponse{id: _id}} ->
        {:ok, response}

      {:ok, %{status_code: 200, body: body}} ->
        {:ok, struct(caller_struct, process_response_body(body))}

      {:ok, %{status_code: _, body: body}} ->
        {:error, struct(Error, process_response_body(body))}

      {:error, %HTTPoison.Error{id: _id, reason: reason}} ->
        {:error, %{error: reason}}
    end
  end

  defp process_request_body(body) when is_tuple(body), do: body
  defp process_request_body(body) when is_map(body), do: Jason.encode!(body)

  defp process_response_body(body) do
    body
    |> Jason.decode!()
    |> Enum.map(fn {k, v} ->
      {String.to_atom(Macro.underscore(k)), v}
    end)
  end
end
