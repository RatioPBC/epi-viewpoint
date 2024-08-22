defmodule EpiViewpointWeb.Features.AuthTest do
  use EpiViewpointWeb.ConnCase, async: true

  import Mox
  setup :verify_on_exit!

  alias EpiViewpoint.Accounts.User
  alias EpiViewpoint.Release
  alias EpiViewpoint.Test
  alias EpiViewpointWeb.Test.Pages

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
    manual_creator = %User{id: "00000000-0000-0000-0000-000000000000"}
    {:ok, url} = Release.create_user(manual_creator, "Test User", @good_email_address, :member, puts: &Function.identity/1)

    #
    # the user visits the reset-password URL, changes their password, sets up multifactor auth, and logs in
    #
    conn
    |> Pages.ResetPassword.visit(url)
    |> Pages.ResetPassword.change_password(@good_password)
    |> Pages.Login.log_in(@good_email_address, @good_password)
    |> Pages.MfaSetup.assert_here()
    |> Pages.MfaSetup.submit_passcode()
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
    |> Pages.Mfa.assert_here()
    |> Pages.Mfa.submit_passcode()
    |> Pages.People.assert_here()
    |> Pages.assert_current_user("Test User")
  end

  @tag :skip
  test "redirecting back to the original page" do
    #
    # with a fresh connection, the user visits a page, logs in, and is redirected back to original page
    #
    # originator = Test.Fixtures.user_attrs(Test.Fixtures.admin(), "originator") |> Accounts.register_user!()
    # person = Test.Fixtures.person_attrs(originator, "person") |> Cases.create_person!()
    #
    # conn
    # |> Pages.Profile.visit(person, :follow_redirect)
    # |> Pages.Login.assert_here()
    # |> Pages.Login.log_in(@good_email_address, @good_password)
    # |> Pages.Mfa.assert_here()
    # |> Pages.Mfa.submit_passcode()
    # |> Pages.Profile.assert_here(person)
    # |> Pages.assert_current_user("Test User")
  end
end
