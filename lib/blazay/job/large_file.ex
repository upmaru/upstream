defmodule Blazay.Job.LargeFile do
  defstruct [:name, :full_path, :stream, :stat, :threads]

  alias Blazay.B2.Account

  @type t() :: %__MODULE__{
    name: String.t,
    full_path: String.t,
    stat: File.Stat.t,
    stream: File.Stream.t,
    threads: integer
  }

  @stream_bytes 2048

  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def add(file_path) do
    __MODULE__ |> Agent.update(fn map -> 
      Map.merge(map, %{file_path => prepare(file_path)})
    end)
  end
  
  def get(file_path) do
    __MODULE__ |> Agent.get(fn map -> 
      Map.fetch(map, file_path)
    end)
  end

  defp prepare(file_path) do
    absolute_path = file_path |> Path.expand
    stat = File.stat!(absolute_path)
    threads = recommend_thread_count(stat.size)
    stream = file_stream(absolute_path, stat.size, threads)

    %__MODULE__{
      name: file_path,
      full_path: absolute_path,
      stat: stat,
      stream: stream,
      threads: threads
    }
  end

  defp recommend_thread_count(file_size) do
    (file_size / Account.recommended_part_size) |> to_integer 
  end

  defp file_stream(absolute_path, file_size, threads) do
    absolute_path
    |> File.stream!([], @stream_bytes)
    |> Stream.chunk(chunk_size(file_size, threads))
  end

  defp chunk_size(file_size, threads) do
    (((file_size / @stream_bytes) |> to_integer) / threads) |> to_integer
  end

  defp to_integer(float) when is_float(float) do
    float |> Float.ceil |> round
  end
end