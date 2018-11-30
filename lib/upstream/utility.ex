defmodule Upstream.Utility do
  @moduledoc """
  Utilities for accessing the upstream upload system
  """
  alias Upstream.{
    B2,
    Store
  }

  def cancel_unfinished_large_files do
    {:ok, unfinished} = B2.LargeFile.unfinished()

    tasks =
      Enum.map(unfinished.files, fn file ->
        Task.async(fn ->
          B2.LargeFile.cancel(file["fileId"])
        end)
      end)

    results = Task.yield_many(tasks, 10_000)
    {:ok, results}
  end

  @spec delete_all_versions(binary()) :: {:error, :failed} | {:ok, [any()]}
  def delete_all_versions(file_name) do
    {:ok, file_ids} = get_file_ids(file_name)

    stream =
      Task.Supervisor.async_stream(
        Upstream.TaskSupervisor,
        file_ids,
        fn file_id ->
          B2.Delete.file_version(file_name, file_id)
        end
      )

    results =
      stream
      |> Enum.to_list()
      |> Enum.map(fn {:ok, result} -> result end)

    responses = Enum.map(results, fn {response, _file_version} -> response end)

    case Enum.uniq(responses) do
      [:ok] ->
        Store.remove(file_name)
        {:ok, results}

      _ ->
        {:error, :failed}
    end
  end

  defp get_file_ids(file_name) do
    case B2.List.by_file_name(file_name) do
      {:ok, %B2.List.FileNames{files: files}} ->
        matching_files =
          Enum.filter(files, fn f ->
            f["fileName"] == file_name
          end)

        {:ok, Enum.map(matching_files, fn f -> f["fileId"] end)}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
