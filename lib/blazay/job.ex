defmodule Blazay.Job do
  @moduledoc """
  Job module for making it easy to work with upload job by exposing 
  file stats and file stream.
  """
  alias Blazay.B2.Account
  require IEx

  defstruct [:name, :full_path, :basename, :stream, :stat, :threads]

  @stream_bytes 2048

  @type t() :: %__MODULE__{
    basename: String.t,
    name: String.t,
    full_path: String.t,
    stat: File.Stat.t,
    stream: File.Stream.t,
    threads: integer
  }

  def create(file_path) do
    basename = Path.basename(file_path)
    absolute_path = Path.expand(file_path)
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

  def recommend_thread_count(file_size) do
    to_integer((file_size / Account.recommended_part_size))
  end

  def file_stream(absolute_path, file_size, threads) do
    chunk_length = chunk_size(file_size, threads)

    absolute_path
    |> File.stream!([], @stream_bytes)
    |> Stream.chunk(chunk_length, chunk_length, [])
  end

  def chunk_size(file_size, threads) do
     to_integer(((to_integer((file_size / @stream_bytes))) / threads))
  end

  def to_integer(float) when is_float(float) do
    float |> Float.ceil |> round
  end
end
