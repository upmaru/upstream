defmodule Blazay.Uploader.Progress do
  def start_link do
    Agent.start_link(fn -> [] end)
  end

  def get(pid) do
    Agent.get(pid, fn reports -> 
      reports
      |> Enum.map(fn {_, progress} -> (progress || 0) end)
      |> Enum.sum
    end)
  end

  def add_bytes_out(bytes, pid, index, thread) do
    Agent.get_and_update(pid, fn reports ->
      Keyword.get_and_update(reports, :"#{index}", fn progress ->
        {:"#{index}", (progress || 0) + (bytes / thread.content_length * 100)}
      end)
    end)
  end
end