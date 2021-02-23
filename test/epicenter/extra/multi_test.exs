defmodule Epicenter.Extra.MultiTest do
  use Epicenter.SimpleCase, async: true
  alias Epicenter.Extra

  describe "get" do
    test "when an :ok tuple, gets the key from the map and wraps its value in an ok tuple" do
      assert Extra.Multi.get({:ok, %{foo: "foo", bar: "bar"}}, :foo) == {:ok, "foo"}
    end

    test "when an :error tuple, returns the error tuple" do
      assert Extra.Multi.get({:error, %{foo: "foo", bar: "bar"}}, :foo) == {:error, %{foo: "foo", bar: "bar"}}
    end
  end
end
