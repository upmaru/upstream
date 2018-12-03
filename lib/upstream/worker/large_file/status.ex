defmodule Upstream.Worker.LargeFile.Status do
  @moduledoc """
  used to track the status of the upload process
  """
  defstruct [:uploaded, :progress]

  @type t :: %__MODULE__{
          uploaded: List.t(),
          progress: map
        }

  # TODO need to track sha1 array order correctly
  @spec start_link() :: {:error, any()} | {:ok, pid()}
  def start_link do
    Agent.start_link(fn ->
      %__MODULE__{
        uploaded: [],
        progress: %{}
      }
    end)
  end

  @spec upload_complete?(atom() | pid() | {atom(), any()} | {:via, atom(), any()}) :: boolean()
  def upload_complete?(pid) do
    progress_count(pid) == uploaded_count(pid)
  end

  @spec uploaded_count(atom() | pid() | {atom(), any()} | {:via, atom(), any()}) :: integer()
  def uploaded_count(pid) do
    Agent.get(pid, fn reports ->
      Enum.count(reports.uploaded)
    end)
  end

  @spec progress_count(atom() | pid() | {atom(), any()} | {:via, atom(), any()}) :: integer()
  def progress_count(pid) do
    Agent.get(pid, fn reports ->
      Enum.count(reports.progress)
    end)
  end

  @spec stop(atom() | pid() | {atom(), any()} | {:via, atom(), any()}) :: :ok
  def stop(pid), do: Agent.stop(pid)

  @spec thread_count(atom() | pid() | {atom(), any()} | {:via, atom(), any()}) :: integer()
  def thread_count(pid) do
    Agent.get(pid, fn reports ->
      Enum.count(reports.progress)
    end)
  end

  @spec bytes_transferred(atom() | pid() | {atom(), any()} | {:via, atom(), any()}) :: integer()
  def bytes_transferred(pid) do
    Agent.get(pid, fn reports ->
      reports.progress
      |> Enum.map(fn {_, transferred} ->
        transferred
      end)
      |> Enum.sum()
    end)
  end

  @spec add_uploaded({any(), any()}, atom() | pid() | {atom(), any()} | {:via, atom(), any()}) ::
          {integer(), binary()}
  def add_uploaded({index, checksum}, pid) do
    Agent.get_and_update(pid, fn reports ->
      new_uploaded = List.insert_at(reports.uploaded, index, checksum)

      {reports, Map.put(reports, :uploaded, new_uploaded)}
    end)

    {index, checksum}
  end

  @spec get_uploaded_sha1(atom() | pid() | {atom(), any()} | {:via, atom(), any()}) :: any()
  def get_uploaded_sha1(pid) do
    Agent.get(pid, fn reports -> reports.uploaded end)
  end

  @spec add_bytes_out(any(), atom() | pid() | {atom(), any()} | {:via, atom(), any()}, any()) ::
          any()
  def add_bytes_out(bytes, pid, key \\ 0) do
    Agent.get_and_update(pid, fn reports ->
      {_old, new_progress} =
        Map.get_and_update(reports.progress, "#{key}", fn transferred ->
          {transferred, (transferred || 0) + bytes}
        end)

      {reports, Map.put(reports, :progress, new_progress)}
    end)
  end
end
