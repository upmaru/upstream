defmodule Blazay do
  use Application
  @moduledoc """
  Documentation for Blazay.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Blazay.hello
      :world

  """
  alias Blazay.B2

  def start(_type, _args) do
    Blazay.Supervisor.start_link()
  end

  @b2_base_api ~S(https://api.backblazeb2.com)
  def base_api, do: @b2_base_api
  
  @config Application.get_env(:blazay, Blazay)
  def config, do: @config
  def config(key), do: Keyword.fetch!(config(), key)

  def cancel_unfinished_large_files do
    {:ok, unfinished} = B2.LargeFile.unfinished

    tasks = unfinished.files |> Enum.map(fn file -> 
      Task.async(fn -> 
        B2.LargeFile.cancel(file["fileId"])
      end)
    end)

    tasks |> Enum.each(fn task -> Task.await(task) end)
  end
end
