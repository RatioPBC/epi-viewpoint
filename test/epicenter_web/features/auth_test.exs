defmodule EpicenterWeb.Features.AuthTest do
  use EpicenterWeb.ConnCase, async: true

  import Mox
  setup :verify_on_exit!

  alias Epicenter.Release
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  @good_email_address "user@example.com"
  @good_password "password123"

  setup do
    stub_with(Test.TOTPMock, Test.TOTPStub)
    :ok
  end

  test "an account is made for a user and then they log in", %{conn: conn} do
    #
    # a user is created manually, and a reset-password URL is created
    #
    {:ok, url} = Release.create_user("Test User", @good_email_address, puts: &Function.identity/1)

    #
    # the user visits the reset-password URL, changes their password, sets up multifactor auth, and logs in
    #
    conn
    |> Pages.ResetPassword.visit(url)
    |> Pages.ResetPassword.change_password(@good_password)
    |> Pages.Login.log_in(@good_email_address, @good_password)
    |> Pages.MfaSetup.assert_here()
    |> Pages.MfaSetup.submit_one_time_password()
    |> Pages.People.assert_here()
    |> Pages.assert_current_user("Test User")

    #
    # with a fresh connection, the user tries to login, making some mistakes along the way
    #
    conn
    |> Pages.Root.visit()
    |> Pages.Login.assert_here()
    |> Pages.Login.log_in("bad-email@example.com", @good_password)
    |> Pages.assert_form_errors(["Invalid email or password"])
    |> Pages.Login.assert_here()
    |> Pages.Login.log_in(@good_email_address, "bad-password")
    |> Pages.assert_form_errors(["Invalid email or password"])
    |> Pages.Login.log_in(@good_email_address, @good_password)
    |> Pages.People.assert_here()
    |> Pages.assert_current_user("Test User")
  end
end
