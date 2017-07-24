defmodule Blazay.Worker.Simple do
  @moduledoc """
  Simple Worker for single threaded uploading
  """
  defmacro __using__(_) do
    quote do
      use GenServer

      @behaviour unquote(__MODULE__)

      alias Blazay.B2.Upload
      alias Blazay.Uploader.TaskSupervisor
      alias Blazay.Worker.Checksum
      alias Blazay.Uploader.Flow

      require Logger

      # Client API

      def start_link(job) do
        GenServer.start_link(__MODULE__, job, name: via_tuple(job.uid.name))
      end

      def upload(job_name) do
        GenServer.cast(via_tuple(job_name), :upload)
      end

      def finish(job_name) do
        GenServer.call(via_tuple(job_name), :finish)
      end

      def stop(job_name) do
        GenServer.call(via_tuple(job_name), :stop)
      end

      # Server Callbacks

      def init(job) do
        {:ok, %{job: job, uid: job.uid, current_state: :started}}
      end

      def handle_cast(:upload, state) do
        Task.Supervisor.start_child TaskSupervisor, fn -> task(state) end
        new_state = Map.merge(state, %{current_state: :uploading})

        {:noreply, new_state}
      end

      def handle_call(:finish, _from, state) do
        new_state = Map.merge(state, %{current_state: :finished})

        if state.job.owner do
          send state.job.owner, {:finished, state.uid.name}
        end

        {:reply, :finished, new_state}
      end

      def handle_call(:stop, _from, state) do
        case state.current_state do
          the_state when the_state in [:started, :uploading] ->
            Logger.info "-----> Cancelling #{state.uid.name}"
            {:stop, :shutdown, state}
          :finished ->
            Logger.info "-----> #{state.uid.name} #{Atom.to_string(state.current_state)}"
            {:stop, :shutdown, state}
        end
      end

      def terminate(reason, state) do
        Logger.info "-----> Shutting down #{state.uid.name}"
        reason
      end

      # Private functions

      defp via_tuple(job_name) do
        {:via, Registry, {Blazay.Uploader.Registry, job_name}}
      end
    end
  end

  @callback task(map) :: {:ok, any} | {:error, any}
end
