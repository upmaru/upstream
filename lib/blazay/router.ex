defmodule Blazay.Router do
  import Plug.Conn
  use Plug.Router

  alias Blazay.Uploader
  alias Blazay.B2

  plug :match

  plug Plug.Parsers,
    parsers: [:multipart],
    pass: ["*/*"],
    length: 100_000_000

  plug :dispatch

  require IEx

  post "/upload/file" do
    %{path: path, filename: filename} =
      conn.body_params[Blazay.file_param]

    Uploader.upload!(path, filename, self())

    case notification_loop() do
      {:success, job_name} ->
        render_json(conn, 200, %{job_name: job_name})
    end
  end

  post "/upload/chunks/start" do
    %{"file_name" => file_name} = conn.body_params

    case B2.LargeFile.start(file_name) do
      {:ok, start} ->
        render_json(conn, 201, start)
      {:error, reason} ->
        render_json(conn, 422, reason)
    end
  end

  delete "/upload/chunks/cancel" do
    %{"file_id" => file_id} = conn.body_params

    case B2.LargeFile.cancel(file_id) do
      {:ok, cancel} ->
        render_json(conn, 200, cancel)
      {:error, reason} ->
        render_json(conn, 422, reason)
    end
  end

  patch "/upload/chunks/add/:file_id" do
    %{"total_parts" => total_parts,
      "part_size"   => part_size,
      "part_number" => part_number} = conn.body_params

    %{path: path, filename: filename} =
      conn.body_params[Blazay.file_param]

    Uploader.upload!(:chunk, file_id, part_number, self())

    case notification_loop() do
      {:success, job_name} ->
        render_json(conn, 200, %{job_name: job_name})
    end
  end

  post "/upload/chunks/finish" do
    %{"file_id" => fiel_id, "sha1" => sha1} = conn.body_params
  end

  defp render_json(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Poison.encode!(body))
  end

  defp notification_loop do
    receive do
      {:finished, job_name} -> {:success, job_name}
      _ -> notification_loop()
    end
  end
end
