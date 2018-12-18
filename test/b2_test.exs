defmodule Upstream.B2Test do
  use ExUnit.Case, async: true

  alias Upstream.B2

  test "upload large file" do
    path = "test/fixtures/large_file_example.mp4"

    {:ok, file} = B2.upload_file(path, "test_b2_video_upload.mov")

    assert file.content_sha1 == "0846d897518b4a99363958098cf0b0b444659b7d"
  end
end
