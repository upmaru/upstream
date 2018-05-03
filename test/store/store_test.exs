defmodule Upstream.StoreTest do
  @moduledoc """
  false
  """
  use ExUnit.Case
  alias Upstream.Store

  test "store value in key" do
    Store.set("blah", "test")

    assert Store.get("blah") == "test"
  end

  test "add member to list" do
    Store.add_member("uploading", "some_job")

    assert Store.get("uploading") == ["some_job"]
  end

  test "move member from 1 list to another" do
    Store.add_member("uploading", "some_job")
    Store.add_member("errored", "another_job")
    Store.move_member("uploading", "errored", "some_job")

    assert Store.get("errored") == ["some_job", "another_job"]
  end

  test "remove item from list" do
    Store.add_member("uploading", "some_job")

    Store.remove_member("uploading", "some_job")

    assert Store.get("uploading") == nil
  end

  test "store and retrieve hash" do
    example_map = %{"blah" => "example", "another" => "test"}
    Store.set("some_hash", example_map)

    assert Store.get("some_hash") == example_map
  end
end
