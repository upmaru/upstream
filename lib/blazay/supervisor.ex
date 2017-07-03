defmodule Blazay.Supervisor do
  @moduledoc """
  Supervisor for the Blazay App
  """
  use Supervisor

  alias Blazay.Uploader

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      worker(Blazay.B2.Account, []),

      supervisor(Uploader.Supervisor, [])
    ]

    supervise(children, strategy: :one_for_one, name: __MODULE__)
  end
end
