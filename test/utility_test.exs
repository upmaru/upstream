defmodule Upstream.UtilityTest do
  @moduledoc """
  false
  """

  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Upstream.{
    Uploader, Store, Utility
  }

  setup do
    Store.start_link([])
    Store.flush_all()
  end

  test "delete_all_versions" do
    path = "test/fixtures/cute_baby.jpg"
    key = "test/utility_test/delete_all_versions/cute_baby_0.jpg"

    Uploader.upload_file!(path, key)
    assert Store.get(key) != nil

    Utility.delete_all_versions(key)
    assert Store.get(key) == nil
  end
end