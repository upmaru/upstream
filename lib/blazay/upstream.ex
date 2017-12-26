defmodule Blazay.Upstream do
  import Blazay.Endpoint

  use Plug.Router

  alias Blazay.Uploader
  alias Blazay.B2

  plug :match

  plug Plug.Parsers,
    parsers: [:multipart],
    pass: ["*/*"],
    length: 100_000_000

  plug :dispatch

  post "/file" do
    %{"file_name" => file_name} = conn.body_params

    %{path: path, filename: _filename} =
      conn.body_params[Blazay.file_param]

    Uploader.upload_file!(path, file_name, self())

    case wait_for_uploader() do
      {:ok, result} ->
        render_json(conn, 200, Map.merge(%{success: true}, result))
      {:error, reason} ->
        render_json(conn, 422, Map.merge(%{success: false}, reason))
    end
  end

  post "/chunks/start" do
    %{"file_name" => file_name} = conn.body_params

    case B2.LargeFile.start(file_name) do
      {:ok, start} ->
        render_json(conn, 201, start)
      {:error, reason} ->
        render_json(conn, 422, reason)
    end
  end

  delete "/chunks/cancel/:file_id" do
    case B2.LargeFile.cancel(file_id) do
      {:ok, cancel} ->
        render_json(conn, 200, cancel)
      {:error, reason} ->
        render_json(conn, 422, reason)
    end
  end

  patch "/chunks/add" do
    %{"file_id" => file_id,
      "part_number" => part_number,
      "chunk_size" => chunk_size} = conn.body_params

    %{path: path, filename: _filename} =
      conn.body_params[Blazay.file_param]

    upload_params = %{
      file_id: file_id,
      index: String.to_integer(part_number),
      content_length: String.to_integer(chunk_size)
    }

    Uploader.upload_chunk!(path, upload_params, self())

    case wait_for_uploader() do
      {:ok, result} ->
        render_json(conn, 200, Map.merge(%{success: true}, result))
      {:error, reason} ->
        render_json(conn, 422, Map.merge(%{success: false}, reason))
    end
  end

  post "/chunks/finish" do
    %{"file_id" => file_id, "shas" => shas} = conn.body_params

    case B2.LargeFile.finish(file_id, Enum.map(shas, fn {_k, v} -> v end)) do
      {:ok, result} ->
        render_json(conn, 200, Map.merge(%{success: true}, result))
      {:error, reason} ->
        render_json(conn, 422, Map.merge(%{success: false}, reason))
    end
  end

  defp wait_for_uploader() do
    receive do
      {:finished, result} -> {:ok, result}
      {:errored, reason} -> {:error, reason}
      _ -> wait_for_uploader()
    end
  end
end
