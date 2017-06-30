defmodule Blazay.B2.UploadTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Blazay.B2.{
    LargeFile, 
    Upload
  }

  setup_all do
    {:ok, %{file_name: "test_file.txt"}}
  end

  test "get the part_url", %{file_name: file_name} do
    use_cassette "b2_get_upload_part_url" do
      {:ok, started} = LargeFile.start(file_name)
      {:ok, part_url} = Upload.part_url(started.file_id)

      assert is_binary(part_url.upload_url)
      assert part_url.file_id == started.file_id
    end
  end

  test "get upload_url" do
    use_cassette "b2_get_upload_url" do
      {:ok, url} = Upload.url

      assert is_binary(url.upload_url)
    end
  end
end