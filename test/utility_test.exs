defmodule Upstream.UtilityTest do
  @moduledoc """
  false
  """

  use ExUnit.Case

  alias Upstream.{
    B2,
    Store,
    Utility
  }

  test "delete_all_versions" do
    path = "test/fixtures/cute_baby.jpg"
    key = "test/utility_test/delete_all_versions/cute_baby_0.jpg"

    auth = B2.Account.authorization()

    B2.upload_file(auth, path, key)
    assert Store.get(key) != nil

    Utility.delete_all_versions(key)
    assert is_nil(Store.get(key))
  end
end
