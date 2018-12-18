defmodule Upstream.B2Test do
  use ExUnit.Case, async: true

  alias Upstream.B2

  test "upload large file" do
    path = "test/fixtures/large_file_example.mp4"

    {:ok, file} = B2.upload_file(path, "test_b2_video_upload.mov")

    assert file.content_sha1 == "E8ABFCC1D1382575CA426E3319D542E7B66FF77B"
  end
end
