defmodule EpicenterWeb.Features.AuthenticationTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Accounts
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  test "a user can log in", %{conn: conn} do
    Test.Fixtures.user_attrs("alice")
    |> Accounts.register_user!()

    Pages.Root.visit(conn)
    |> Pages.Login.log_in("alice@example.com", "password123")
    |> Pages.People.assert_here()
  end

  # test "a user cannot log in with a non-existant email address" do
  # end
  #
  # test "a user cannot log in with an incorrect password" do
  # end
  #
  # test "a user with an unconfirmed email address must confirm before logging in" do
  # end
end
