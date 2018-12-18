defmodule Upstream.B2Test do
  use ExUnit.Case, async: true

  alias Upstream.B2

  test "upload large file" do
    path = "test/fixtures/large_file_example.mp4"

    {:ok, file} = B2.upload_file(path, "test_b2_video_upload.mov")

    assert file == finish_response
  end
end
