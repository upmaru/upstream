defmodule Blazay.Utility do
  alias Blazay.B2

  def cancel_unfinished_large_files do
    {:ok, unfinished} = B2.LargeFile.unfinished

    tasks = unfinished.files |> Enum.map(fn file -> 
      Task.async(fn ->
        B2.LargeFile.cancel(file["fileId"])
      end)
    end)

    tasks |> Enum.each(fn task -> Task.await(task) end)
  end
end