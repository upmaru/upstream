defmodule Upstream.B2Test do
  use ExUnit.Case

  alias Upstream.B2

  test "upload large file" do
    path = "test/fixtures/learn_react_on_rails.mov"

    {:ok, file} = B2.upload_file(path, "test_b2_video_upload.mov")

    IO.inspect file
  end
end
