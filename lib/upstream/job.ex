defmodule Upstream.Job do
  @moduledoc """
  Job module for making it easy to work with upload job by exposing 
  file stats and file stream.
  """
  alias Upstream.B2.Account

  defstruct [:uid, :full_path, :basename, :stream, :content_length,
             :last_content_length, :stat, :threads, :owner]

  @stream_bytes 2048

  @type t() :: %__MODULE__{
    basename: String.t,
    uid: map,
    full_path: String.t,
    stat: File.Stat.t,
    content_length: integer,
    last_content_length: integer,
    stream: File.Stream.t,
    threads: integer,
    owner: pid | nil
  }

  def create(source_path, params, owner) do
    absolute_path = Path.expand(source_path)

    stat = File.stat!(absolute_path)
    threads = recommend_thread_count(stat.size)

    # calculates the chunk length based on how many threads
    chunk_length = chunk_size(stat.size, threads)

    # get the stream chunked or not chunked
    stream = file_stream(absolute_path, chunk_length, threads)

    # calculate the content_length
    content_length =
      get_content_length(params) || chunk_length * @stream_bytes

    # content_length of the last thread
    last_content_length =
      (stat.size - (content_length * threads)) + content_length

    %__MODULE__{
      uid: get_uid(params) || %{name: source_path},
      full_path: absolute_path,
      stat: stat,
      content_length: content_length,
      last_content_length: last_content_length,
      stream: stream,
      threads: threads,
      owner: owner
    }
  end

  defp get_uid(params) when is_binary(params), do: %{name: params}
  defp get_uid(params) when is_map(params), do: %{
    file_id: params.file_id, index: params.index, name: "#{params.file_id}_#{params.index}"
  }

  defp recommend_thread_count(file_size) do
    to_integer((file_size / Account.recommended_part_size))
  end

  defp file_stream(absolute_path, chunk_length, threads) do
    stream = File.stream!(absolute_path, [], @stream_bytes)

    if threads == 1, do: stream,
      else: Stream.chunk(stream, chunk_length, chunk_length, [])
  end

  defp get_content_length(params) when is_binary(params), do: nil
  defp get_content_length(params) when is_map(params) do
    if Map.has_key?(params, :content_length),
      do: params.content_length, else: nil
  end

  defp chunk_size(file_size, threads) do
     to_integer(((to_integer((file_size / @stream_bytes))) / threads))
  end

  defp to_integer(float) when is_float(float) do
    float |> Float.ceil |> round
  end
end
