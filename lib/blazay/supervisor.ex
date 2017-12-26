defmodule Blazay.Supervisor do
  @moduledoc """
  Supervisor for the Blazay App
  """
  use Supervisor

  alias Blazay.B2.Account
  alias Blazay.Uploader

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      worker(Account, []),
      supervisor(Uploader, [])
    ]

    supervise(children, strategy: :simple_one_for_one, name: __MODULE__)
  end
end
