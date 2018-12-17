defmodule Upstream.B2.RoutesTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Upstream.B2
  alias B2.Routes

  @opts Routes.init([])

  setup_all do
    auth = B2.Account.authorization()

    on_exit(fn ->
      Upstream.Utility.cancel_unfinished_large_files()
    end)

    {:ok, %{auth: auth}}
  end


  test "GET /chunks/unfinished" do
    conn =
      conn(:get, "/chunks/unfinished")
      |> Routes.call(@opts)

    assert conn.status == 200
  end

  test "POST /chunks/start" do
    conn =
      conn(:post, "/chunks/start", %{"file_name" => "test_routes.jpg"})
      |> Routes.call(@opts)

    assert conn.status == 201
  end

  test "DELETE /chunks/cancel/:file_id", %{auth: auth} do
    {:ok, file} = B2.LargeFile.start(auth, "test_routes_delete_file.mov")

    conn =
      conn(:delete, "/chunks/cancel/#{file.file_id}")
      |> Routes.call(@opts)

    assert conn.status == 200
  end
end
