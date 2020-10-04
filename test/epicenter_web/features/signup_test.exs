defmodule EpicenterWeb.Features.SignupTest do
  use EpicenterWeb.ConnCase, async: true

  import Mox
  setup :verify_on_exit!

  alias Epicenter.Release
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  setup do
    stub_with(Test.TOTPMock, Test.TOTPStub)
    :ok
  end

  test "an account is made for a user and then they log in", %{conn: conn} do
    #
    # a user is created manually, and a reset-password URL is created
    #
    {:ok, url} = Release.create_user("Test User", "user@example.com", puts: &Function.identity/1)

    #
    # the user visits the reset-password URL, changes their password, sets up multifactor auth, and logs in
    #
    conn
    |> Pages.ResetPassword.visit(url)
    |> Pages.ResetPassword.change_password("password123")
    |> Pages.Login.log_in("user@example.com", "password123")
    |> Pages.MfaSetup.assert_here()
    |> Pages.MfaSetup.submit_one_time_password()
    |> Pages.People.assert_here()
    |> Pages.assert_current_user("Test User")

    #
    # with a fresh connection, the user can log in
    #
    conn
    |> Pages.Root.visit()
    |> Pages.Login.assert_here()
    |> Pages.Login.log_in("user@example.com", "password123")
    |> Pages.People.assert_here()
    |> Pages.assert_current_user("Test User")
  end
end
