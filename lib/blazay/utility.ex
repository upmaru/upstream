defmodule Upstream.Utility do
  @moduledoc """
  Utilities for accessing the upstream upload system
  """
  alias Upstream.B2

  def cancel_unfinished_large_files do
    {:ok, unfinished} = B2.LargeFile.unfinished

    tasks = Enum.map(unfinished.files, fn file ->
      Task.async(fn ->
        B2.LargeFile.cancel(file["fileId"])
      end)
    end)

    results = Task.yield_many(tasks, 10_000)
    {:ok, results}
  end
end
