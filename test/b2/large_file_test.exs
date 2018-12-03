defmodule Upstream.B2.LargeFileTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Upstream.B2.{
    LargeFile,
    Account
  }

  setup_all do
    authorization = Account.authorization()

    {:ok, %{auth: authorization, file_name: "test_file.txt"}}
  end

  test "makes a call to start large_file", %{auth: auth, file_name: file_name} do
    {:ok, started} =
      use_cassette "b2_start_large_file" do
        LargeFile.start(auth, file_name)
      end

    assert started.account_id == Upstream.storage(:account_id)
    assert is_binary(started.file_id)
  end

  test "makes a call to cancel large_file", %{auth: auth, file_name: file_name} do
    {:ok, cancelled} =
      use_cassette "b2_cancel_large_file" do
        {:ok, started} = LargeFile.start(auth, file_name)
        LargeFile.cancel(auth, started.file_id)
      end

    assert cancelled.file_name == file_name
  end
end
