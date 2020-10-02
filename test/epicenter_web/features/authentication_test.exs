defmodule EpicenterWeb.Features.AuthenticationTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Accounts
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  @good_email_address "user@example.com"
  @good_password "password123"

  def create_confirmed_user(),
    do: create_unconfirmed_user() |> Test.Accounts.confirm_user!()

  def create_unconfirmed_user(),
    do: Test.Fixtures.user_attrs("user", email: @good_email_address, password: @good_password) |> Accounts.register_user!()

  test "a user can log in", %{conn: conn} do
    create_confirmed_user()

    Pages.Root.visit(conn)
    |> Pages.Login.log_in(@good_email_address, @good_password)
    |> Pages.People.assert_here()
  end

  test "a user cannot log in with a non-existant email address", %{conn: conn} do
    create_confirmed_user()

    Pages.Root.visit(conn)
    |> Pages.Login.log_in("not-a-user@example.com", @good_password)
    |> assert_eq({:error, ["Invalid email or password"]})
  end

  test "a user cannot log in with an incorrect password", %{conn: conn} do
    create_confirmed_user()

    Pages.Root.visit(conn)
    |> Pages.Login.log_in(@good_email_address, "totally-the-wrong-password")
    |> assert_eq({:error, ["Invalid email or password"]})
  end

  test "a user with an unconfirmed email address must confirm before logging in", %{conn: conn} do
    user = create_unconfirmed_user()

    Pages.Root.visit(conn)
    |> Pages.Login.log_in(@good_email_address, @good_password)
    |> assert_eq({:error, ["Your email address must be confirmed before you can log in"]})

    user |> Test.Accounts.confirm_user!()

    Pages.Root.visit(conn)
    |> Pages.Login.log_in(@good_email_address, @good_password)
    |> Pages.People.assert_here()
  end
end
