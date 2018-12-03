defmodule Upstream.Worker.Base do
  @moduledoc """
  Simple Worker for single threaded uploading
  """
  defmacro __using__(_) do
    quote do
      use GenServer

      @upload_timeout Application.get_env(:upstream, :upload)[:timeout] || 20_000

      @behaviour unquote(__MODULE__)

      alias Upstream.Job
      alias Upstream.B2.Upload

      alias Upstream.Worker.{
        Checksum,
        Flow
      }

      alias Upstream.B2.Account

      require Logger

      # Client API

      def start_link(job) do
        GenServer.start_link(__MODULE__, job)
      end

      def upload(pid) do
        GenServer.call(pid, :upload, @upload_timeout)
      end

      # Server Callbacks

      @impl true
      def init(job) do
        Job.State.start(job)

        {:ok, handle_setup(%{job: job, current_state: :started})}
      end

      @impl true
      def handle_call(:upload, _from, %{job: job} = state) do
        case task(state) do
          {:ok, result} ->
            Job.State.complete(job, result)

            {:stop, :normal, {:ok, result},
             Map.merge(state, %{
               current_state: :uploaded
             })}

          {:error, reason} ->
            Job.State.error(job, reason)

            {:stop, {:error, reason}, {:error, reason},
             Map.merge(state, %{
               current_state: :upload_failed
             })}
        end
      end

      @impl true
      def terminate(reason, %{job: job} = state) do
        handle_stop(state)

        cond do
          Job.State.completed?(job) ->
            Logger.info("[Upstream] Completed #{job.uid.name}")

          Job.State.errored?(job) ->
            Logger.info("[Upstream] Errored #{job.uid.name}")

          true ->
            Job.State.error(job, %{error: reason})
        end

        reason
      end

      defp handle_setup(state), do: state
      defp handle_stop(state), do: {:ok, state.current_state}

      defoverridable handle_stop: 1, handle_setup: 1
    end
  end

  @callback task(map) :: {:ok, any} | {:error, any}
end
