defmodule Epicenter.AccountsTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Accounts
  alias Epicenter.Test

  test "create_user creates a user" do
    {:ok, user} = Test.Fixtures.user_attrs("alice") |> Accounts.create_user()

    assert user.tid == "alice"
    assert user.username == "alice"
  end

  test "create_user! creates a user" do
    user = Test.Fixtures.user_attrs("alice") |> Accounts.create_user!()

    assert user.tid == "alice"
    assert user.username == "alice"
  end
end
