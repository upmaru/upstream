defmodule Blazay.Entry.LargeFile do
  defstruct [:name, :full_path, :basename, :stream, :stat, :threads]

  alias Blazay.B2.Account

  @stream_bytes 2048

  @type t() :: %__MODULE__{
    basename: String.t,
    name: String.t,
    full_path: String.t,
    stat: File.Stat.t,
    stream: File.Stream.t,
    threads: integer
  }

  def prepare(file_path) do
    basename = file_path |> Path.basename
    absolute_path = file_path |> Path.expand
    stat = File.stat!(absolute_path)
    threads = recommend_thread_count(stat.size)
    stream = file_stream(absolute_path, stat.size, threads)

    %__MODULE__{
      name: file_path,
      full_path: absolute_path,
      basename: basename,
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