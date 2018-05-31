defmodule Upstream.Worker.Base do
  @moduledoc """
  Simple Worker for single threaded uploading
  """
  defmacro __using__(_) do
    quote do
      use GenServer

      @behaviour unquote(__MODULE__)

      alias Upstream.Job
      alias Upstream.B2.Upload

      alias Upstream.Uploader.{
        TaskSupervisor,
        Checksum,
        Flow
      }

      require Logger

      # Client API

      def start_link(job) do
        GenServer.start_link(__MODULE__, job, name: via_tuple(job.uid.name))
      end

      def upload(job_name) do
        GenServer.call(via_tuple(job_name), :upload, :infinity)
      end

      # Server Callbacks

      def init(job) do
        Job.start(job)

        {:ok, handle_setup(%{job: job, uid: job.uid, current_state: :started})}
      end

      def handle_call(:upload, _from, state) do
        case task(state) do
          {:ok, result} ->
            Job.complete(state, result)
            {:stop, :normal, {:ok, result},
             Map.merge(state, %{
               current_state: :uploaded
             })}

          {:error, reason} ->
            Job.error(state, reason)
            {:stop, {:error, reason}, {:error, reason},
             Map.merge(state, %{
               current_state: :upload_failed
             })}
        end
      end

      def terminate(reason, state) do
        handle_stop(state)
        Logger.info("[Upstream] Shutting down #{state.uid.name}")
        reason
      end

      # Private functions

      defp handle_stop(state), do: nil
      defp handle_setup(state), do: state

      defp via_tuple(job_name) do
        {:via, Registry, {Upstream.Registry, job_name}}
      end

      defoverridable handle_stop: 1, handle_setup: 1
    end
  end

  @callback task(map) :: {:ok, any} | {:error, any}
end
