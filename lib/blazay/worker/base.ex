defmodule Blazay.Worker.Base do
  @moduledoc """
  Simple Worker for single threaded uploading
  """
  defmacro __using__(_) do
    quote do
      use GenServer

      @behaviour unquote(__MODULE__)

      alias Blazay.B2.Upload
      alias Blazay.Uploader.{
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
        GenServer.cast(via_tuple(job_name), :upload)
      end

      def finish(job_name, result) do
        GenServer.call(via_tuple(job_name), {:finish, result})
      end

      def error(job_name, reason) do
        GenServer.call(via_tuple(job_name), {:error, reason})
      end

      def stop(job_name) do
        GenServer.call(via_tuple(job_name), :stop)
      end

      # Server Callbacks

      def init(job) do
        {:ok, handle_setup(%{job: job, uid: job.uid, current_state: :started})}
      end

      def handle_cast(:upload, state) do
        Task.Supervisor.start_child TaskSupervisor, fn ->
          case task(state) do
            {:ok, result}    -> finish(state.uid.name, result)
            {:error, reason} -> error(state.uid.name, reason)
          end
          stop(state.uid.name)
        end
        new_state = Map.merge(state, %{current_state: :uploading})

        {:noreply, new_state}
      end

      def handle_call({:finish, result}, _from, state) do
        new_state = Map.merge(state, %{
          current_state: :finished, result: result
        })

        if state.job.owner do
          send state.job.owner, {:finished, result}
        end

        {:reply, :finished, new_state}
      end

      def handle_call({:error, reason}, _from, state) do
        new_state = Map.merge(state, %{
          current_state: :errored, result: reason
        })

        if state.job.owner do
          send state.job.owner, {:errored, reason}
        end

        {:reply, :errored, new_state}
      end

      def handle_call(:stop, _from, state) do
        handle_stop(state)

        case state.current_state do
          the_state when the_state in [:started, :uploading] ->
            Logger.info "-----> Stopping #{state.uid.name}"
            {:stop, :shutdown, state}
          :errored ->
            Logger.info "-----> Errored #{state.uid.name}"
            {:stop, :shutdown, state}
          :finished ->
            Logger.info "-----> #{state.uid.name} #{Atom.to_string(state.current_state)}"
            {:stop, :shutdown, state}
          :cancelled ->
            Logger.info "-----> Cancelled #{state.job.uid.name}"
            {:stop, :shutdown, state}
        end
      end

      def terminate(reason, state) do
        Logger.info "-----> Shutting down #{state.uid.name}"
        reason
      end

      # Private functions

      defp handle_stop(state), do: nil
      defp handle_setup(state), do: state

      defp via_tuple(job_name) do
        {:via, Registry, {Blazay.Uploader.Registry, job_name}}
      end

      defoverridable [init: 1, handle_stop: 1, handle_setup: 1]
    end
  end

  @callback task(map) :: {:ok, any} | {:error, any}
end
