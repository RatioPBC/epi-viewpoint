defmodule EpiViewpointWeb.UserMultifactorAuthControllerTest do
  use EpiViewpointWeb.ConnCase, async: true

  import EpiViewpoint.AccountsFixtures
  import Mox
  setup :verify_on_exit!

  alias EpiViewpoint.Test
  alias EpiViewpoint.Test.TOTPStub
  alias EpiViewpointWeb.Session
  alias EpiViewpointWeb.Test.Pages

  setup do
    %{user: user_fixture()}
  end

  setup do
    stub_with(Test.TOTPMock, Test.TOTPStub)
    :ok
  end

  describe "new" do
    test "renders the multifactor auth page", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user, second_factor_authenticated: false) |> get(~p"/users/mfa")
      assert response = html_response(conn, 200)
      Pages.Mfa.assert_here(response)
    end
  end

  describe "create" do
    test "remembers mfa success in session when successful", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user, second_factor_authenticated: false)
        |> post(~p"/users/mfa?#{%{"user" => %{"passcode" => TOTPStub.valid_passcode()}}}")
        |> Pages.follow_conn_redirect()
        |> Pages.assert_form_errors([])
        |> Pages.People.assert_here()

      assert Session.multifactor_auth_success?(conn)
    end

    test "renders 'new' with an error when unsuccessful", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user, second_factor_authenticated: false)
        |> post(~p"/users/mfa?#{%{"user" => %{"passcode" => "000000"}}}")
        |> Pages.assert_form_errors(["The six-digit code was incorrect"])

      refute Session.multifactor_auth_success?(conn)
    end
  end
end
