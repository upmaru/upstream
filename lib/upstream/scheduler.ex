defmodule Upstream.Scheduler do
  @moduledoc """
  For Running recurring tasks like renewing auth token
  """

  use GenServer

  require Logger

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  @impl true
  @spec init(any()) :: :ignore | {:ok, nil}
  def init(_) do
    if enabled?() do
      start_scheduler()
      {:ok, nil}
    else
      :ignore
    end
  end

  @impl true
  def handle_info(:perform, state) do
    Upstream.B2.Account.re_authorize()
    schedule_next()
    {:noreply, state}
  end

  def handle_info(:schedule, state) do
    Logger.info("[Upstream] Starting scheduler...")
    schedule_next()
    {:noreply, state}
  end

  defp start_scheduler() do
    Process.send_after(self(), :schedule, :timer.seconds(5))
  end

  defp schedule_next() do
    Process.send_after(self(), :perform, :timer.hours(23))
  end

  defp enabled?() do
    Application.get_env(:upstream, Upstream)[:scheduler]
  end
end
