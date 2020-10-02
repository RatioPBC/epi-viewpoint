defmodule EpicenterWeb.Features.AuthenticationTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Accounts
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  @good_email_address "user@example.com"
  @good_password "password123"

  test "a user can log in", %{conn: conn} do
    Test.Fixtures.user_attrs("user")
    |> Accounts.register_user!()

    Pages.Root.visit(conn)
    |> Pages.Login.log_in(@good_email_address, @good_password)
    |> Pages.People.assert_here()
  end

  test "a user cannot log in with a non-existant email address", %{conn: conn} do
    Pages.Root.visit(conn)
    |> Pages.Login.log_in("not-a-user@example.com", @good_password)
    |> assert_eq({:error, ["Invalid email or password"]})
  end

  test "a user cannot log in with an incorrect password", %{conn: conn} do
    Test.Fixtures.user_attrs("user")
    |> Accounts.register_user!()

    Pages.Root.visit(conn)
    |> Pages.Login.log_in(@good_email_address, "totally-the-wrong-password")
    |> assert_eq({:error, ["Invalid email or password"]})
  end

  # test "a user with an unconfirmed email address must confirm before logging in" do
  # end
end
