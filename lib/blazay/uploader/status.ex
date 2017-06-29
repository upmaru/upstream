defmodule Blazay.Uploader.Status do
  alias Blazay.Uploader.Supervisor

  def start_link do
    Agent.start_link(fn -> [] end)
  end

  def stop(pid), do: Agent.stop(pid)

  def get(pid) do
    Agent.get(pid, fn reports -> 
      reports
      |> Enum.map(fn {_, status} -> (status || 0) end)
      |> Enum.sum
      |> Float.round(2)
    end)
  end

  def add_bytes_out(bytes, pid, index, thread) do
    Agent.get_and_update(pid, fn reports ->
      Keyword.get_and_update(reports, :"#{index}", fn status ->
        {:"#{index}", (status || 0) + (bytes / thread.content_length * 100)}
      end)
    end)
  end

  def verify_and_finish(results, pid, entry, threads) do
    counted = 
      results
      |> Enum.reduce(%{}, fn(result, acc) -> 
        Map.update(acc, result, 1, &(&1 + 1))
      end)

    if get(pid) == 100.0 && counted.ok == Enum.count(threads) do
      Supervisor.finish_large_file(entry.name)
    end
  end
end