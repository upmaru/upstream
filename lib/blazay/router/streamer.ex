defmodule Blazay.Router.Streamer do
  use GenServer
  alias Plug.Conn

  require IEx

  # Client API

  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def write(pid, conn), do: GenServer.cast(pid, {:write, conn})

  # Server Callbacks

  def init(:ok) do
    {:ok, []}
  end

  def handle_cast({:write, conn}, buffer) do
    {:noreply, write_to_buffer(conn, buffer)}
  end

  defp write_to_buffer(conn, buffer) do
    case Conn.read_body(conn) do
      {:ok, body, new_conn} ->
        Enum.into([body], buffer)
      {:more, body_part, new_conn} ->
        Enum.into([body_part], buffer)
        write_to_buffer(new_conn, buffer)
    end
  end
end
