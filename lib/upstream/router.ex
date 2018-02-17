defmodule Upstream.Router do
  @moduledoc """
  Provides the Endpoints for uploading
  """

  import Upstream.Endpoint

  use Plug.Router

  alias Upstream.Uploader
  alias Upstream.B2

  plug(:match)

  plug(
    Plug.Parsers,
    parsers: [:multipart],
    pass: ["*/*"],
    length: 100_000_000
  )

  plug(:dispatch)

  get "/chunks/unfinished" do
    case B2.LargeFile.Unfinished.call() do
      {:ok, unfinished} ->
        render_json(conn, 200, unfinished)

      {:error, reason} ->
        render_json(conn, 422, reason)
    end
  end

  get "/chunks/resume/:file_id" do
    case B2.LargeFile.ListParts.call(body: file_id) do
      {:ok, %B2.LargeFile.ListParts{parts: parts}} ->
        shas = B2.LargeFile.ListParts.extract_shas(parts)
        render_json(conn, 200, %{shas: shas})

      {:error, reason} ->
        render_json(conn, 422, reason)
    end
  end

  get "/source/:prefix/*path" do
    render_json(conn, 200, %{
      sequences: [
        %{
          clips: [
            %{
              type: "source",
              path: get_location(prefix, path)
            }
          ]
        }
      ]
    })
  end

  defp get_location(prefix, path) do
    {:ok, %{authorization_token: token}} = B2.Download.authorize(prefix, 3600)

    ["/" <> Upstream.config(:bucket_name), prefix, path, token]
    |> List.flatten()
    |> Enum.join("/")
  end

  post "/file" do
    %{"file_name" => file_name} = conn.body_params

    %{path: path, filename: _filename} = conn.body_params[Upstream.file_param()]

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

  require IEx

  patch "/chunks/add" do
    IEx.pry()

    %{"file_id" => file_id, "part_number" => part_number, "chunk_size" => chunk_size} =
      conn.body_params

    %{path: path, filename: _filename} = conn.body_params[Upstream.file_param()]

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
