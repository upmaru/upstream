defmodule Blazay.Job do
  @moduledoc """
  Job module for making it easy to work with upload job by exposing 
  file stats and file stream.
  """
  alias Blazay.B2.Account
  require IEx

  defstruct [:name, :full_path, :basename, :stream, :content_length, :last_content_length, :stat, :threads]

  @stream_bytes 2048

  @type t() :: %__MODULE__{
    basename: String.t,
    name: String.t,
    full_path: String.t,
    stat: File.Stat.t,
    content_length: integer,
    last_content_length: integer,
    stream: File.Stream.t,
    threads: integer
  }

  def create(file_path) do
    basename = Path.basename(file_path)
    absolute_path = Path.expand(file_path)

    stat = File.stat!(absolute_path)
    threads = recommend_thread_count(stat.size)

    # calculates the chunk length based on how many threads
    chunk_length = chunk_size(stat.size, threads)

    # get the stream chunked or not chunked
    stream = file_stream(absolute_path, chunk_length, threads)

    # calculate the content_length
    content_length = chunk_length * @stream_bytes

    # content_length of the last thread
    last_content_length =
      (stat.size - (content_length * threads)) + content_length

    %__MODULE__{
      name: file_path,
      full_path: absolute_path,
      basename: basename,
      stat: stat,
      content_length: content_length,
      last_content_length: last_content_length,
      stream: stream,
      threads: threads
    }
  end

  def recommend_thread_count(file_size) do
    to_integer((file_size / Account.recommended_part_size))
  end

  def file_stream(absolute_path, chunk_length, threads) do
    stream = File.stream!(absolute_path, [], @stream_bytes)

    if threads == 1, do: stream,
      else: Stream.chunk(stream, chunk_length, chunk_length, [])
  end

  def chunk_size(file_size, threads) do
     to_integer(((to_integer((file_size / @stream_bytes))) / threads))
  end

  def to_integer(float) when is_float(float) do
    float |> Float.ceil |> round
  end
end
