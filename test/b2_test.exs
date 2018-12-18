defmodule Upstream.B2Test do
  use ExUnit.Case, async: true

  import Mox

  alias Upstream.B2

  setup :set_mox_global
  setup :verify_on_exit!

  test "upload large file" do
    Upstream.B2.UploadMock
    |> expect(:part, 2, fn _auth, _url, _header, _body ->
      {:ok, %Upstream.B2.Upload.Part{
        file_id: "example_file_id_0",
        content_sha1: "somesha1",
        part_number: "1",
        content_length: "2333000"
      }}
    end)

    finish_response = %Upstream.B2.LargeFile.Finish{
      file_id: "example_file_id",
      file_name: "test_b2_video_upload.mov",
      account_id: "some_account",
      bucket_id: "test_bucket",
      content_length: 203203920,
      content_sha1: "somesha1",
      content_type: "content/type",
      file_info: %{},
      action: "upload",
      upload_timestamp: 20181201
    }

    Upstream.B2.LargeFileMock
    |> expect(:finish, fn _auth, _file_name, _sha1_array ->
      {:ok, finish_response}
    end)

    path = "test/fixtures/large_file_example.mp4"

    {:ok, file} = B2.upload_file(path, "test_b2_video_upload.mov")

    assert file == finish_response
  end
end
