defmodule Upstream.Job.State do
  @moduledoc """
  Handles Querying and Manipulating of Job States
  """
  use Upstream.Constants
  alias Upstream.Store

  @spec uploading?(Upstream.Job.t()) :: boolean()
  def uploading?(job) do
    Store.is_member?(@uploading, job.uid.name)
  end

  @spec completed?(Upstream.Job.t()) :: boolean()
  def completed?(job) do
    Store.exist?(job.uid.name) && not Store.is_member?(@errored, job.uid.name) &&
      not Store.is_member?(@uploading, job.uid.name)
  end

  @spec done?(Upstream.Job.t()) :: boolean()
  def done?(job) do
    completed?(job) || (errored?(job) && not uploading?(job))
  end

  @spec errored?(Upstream.Job.t()) :: boolean()
  def errored?(job) do
    Store.is_member?(@errored, job.uid.name)
  end

  @spec retry(Upstream.Job.t()) :: :error | :ok
  def retry(job) do
    Store.remove(job.uid.name)
    Store.remove_member(@errored, job.uid.name)
  end

  @spec start(Upstream.Job.t()) :: {:error, :already_exists} | {:ok, any()}
  def start(job) do
    Store.add_member(@uploading, job.uid.name)
  end

  @spec error(Upstream.Job.t(), any()) :: any()
  def error(job, reason) do
    Store.set(job.uid.name, Poison.encode!(reason))
    Store.move_member(@uploading, @errored, job.uid.name)
  end

  @spec complete(Upstream.Job.t(), any()) :: :error | :ok
  def complete(job, result) do
    Store.set(job.uid.name, Poison.encode!(result))
    Store.remove_member(@uploading, job.uid.name)
  end

  @spec get_result(Upstream.Job.t(), :infinity | non_neg_integer()) :: any()
  def get_result(job, timeout \\ 5000) do
    task = Task.async(fn -> wait_for_result(job) end)

    case Task.yield(task, timeout) || Task.shutdown(task) do
      {:ok, reply} ->
        reply

      nil ->
        message = %{error: :no_reply}
        error(job, message)
        {:error, message}
    end
  end

  defp wait_for_result(job) do
    cond do
      completed?(job) ->
        {:ok, Poison.decode!(Store.get(job.uid.name))}

      errored?(job) ->
        {:error, Poison.decode!(Store.get(job.uid.name))}

      true ->
        wait_for_result(job)
    end
  end
end
