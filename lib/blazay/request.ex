defmodule Blazay.Request do
  alias Blazay.Error

  @spec post(struct, String.t, List.t, Keyword.t) :: {:ok | :error, %Error{} | struct}
  def post(caller_struct, url, body, headers) do
    case HTTPoison.post(url, body, headers) do
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