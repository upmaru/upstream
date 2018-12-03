defmodule Upstream.B2.DeleteTest do
  @moduledoc """
  false
  """
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Upstream.B2.{
    Delete,
    Upload,
    Account
  }

  setup_all do
    authorization = Account.authorization()

    {:ok, %{auth: authorization, file_name: "test_file_deletion.txt"}}
  end

  test "file_version", %{auth: auth, file_name: file_name} do
    stream = Stream.map(1..10_000, fn n -> <<n>> end)

    sha1 =
      stream
      |> Enum.reduce(:crypto.hash_init(:sha), fn bytes, acc ->
        :crypto.hash_update(acc, bytes)
      end)
      |> :crypto.hash_final()
      |> Base.encode16()
      |> String.downcase()

    {:ok, url} = Upload.url(auth)

    header = %{
      authorization: url.authorization_token,
      file_name: file_name,
      content_length: 10_000,
      x_bz_content_sha1: sha1
    }

    {:ok, file} = Upload.file(auth, url.upload_url, header, stream)

    assert Delete.file_version(auth, file_name, file.file_id) ==
             {:ok, %Upstream.B2.Delete.FileVersion{file_id: file.file_id, file_name: file_name}}
  end
end
