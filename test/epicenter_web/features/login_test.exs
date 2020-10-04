defmodule EpicenterWeb.Features.LoginTest do
  use EpicenterWeb.ConnCase, async: true

  import Mox
  setup :verify_on_exit!

  alias Epicenter.Accounts
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  @good_email_address "user@example.com"
  @good_password "password123"

  setup do
    stub_with(Test.TOTPMock, Test.TOTPStub)
    :ok
  end

  def create_user(:confirmed, :mfa),
    do: create_user(:confirmed) |> Accounts.update_user_mfa!(Epicenter.Test.TOTPStub.encoded_secret())

  def create_user(:confirmed),
    do: create_user() |> Test.Accounts.confirm_user!()

  def create_user(),
    do: Test.Fixtures.user_attrs("test-user", name: "Test User", email: @good_email_address, password: @good_password) |> Accounts.register_user!()

  test "a user can log in", %{conn: conn} do
    create_user(:confirmed, :mfa)

    Pages.Root.visit(conn)
    |> Pages.Login.log_in(@good_email_address, @good_password)
    |> Pages.People.assert_here()
    |> Pages.assert_current_user("Test User")
  end

  test "a user cannot log in with a non-existant email address", %{conn: conn} do
    create_user(:confirmed, :mfa)

    Pages.Root.visit(conn)
    |> Pages.Login.log_in("not-a-user@example.com", @good_password)
    |> assert_eq({:error, ["Invalid email or password"]})
  end

  test "a user cannot log in with an incorrect password", %{conn: conn} do
    create_user(:confirmed, :mfa)

    Pages.Root.visit(conn)
    |> Pages.Login.log_in(@good_email_address, "totally-the-wrong-password")
    |> assert_eq({:error, ["Invalid email or password"]})
  end

  test "a user with an unconfirmed email address must confirm and add mfa before logging in", %{conn: conn} do
    user = create_user()

    Pages.Root.visit(conn)
    |> Pages.Login.log_in(@good_email_address, @good_password)
    |> assert_eq({:error, ["Your email address must be confirmed before you can log in"]})

    user |> Test.Accounts.confirm_user!()

    Pages.Root.visit(conn)
    |> Pages.Login.assert_here()
    |> Pages.Login.log_in(@good_email_address, @good_password)
    |> Pages.MfaSetup.assert_here()
    |> Pages.MfaSetup.submit_one_time_password()
    |> Pages.People.assert_here()
    |> Pages.assert_current_user("Test User")
  end
end
