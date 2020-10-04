defmodule EpicenterWeb.UserMultifactorAuthControllerTest do
  use EpicenterWeb.ConnCase, async: true

  import Mox
  setup :verify_on_exit!

  alias Epicenter.Test
  alias EpicenterWeb.Session
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  setup do
    stub_with(Test.TOTPMock, Test.TOTPStub)
    :ok
  end

  describe "new" do
    test "renders a qr code and key", %{conn: conn} do
      doc =
        conn
        |> get(Routes.user_multifactor_auth_path(conn, :new))
        |> html_response(200)
        |> Test.Html.parse_doc()

      assert doc |> Test.Html.text(role: "key") == Test.TOTPStub.encoded_secret()
      assert doc |> Test.Html.present?(role: "qr-code")
    end
  end

  describe "create" do
    test "redirects to '/' when correct totp code is entered", %{conn: conn} do
      params = %{"mfa" => %{"totp" => Test.TOTPStub.valid_otp()}}

      conn
      |> Session.put_multifactor_auth_secret({Test.TOTPStub.raw_secret(), Test.TOTPStub.encoded_secret()})
      |> post(Routes.user_multifactor_auth_path(conn, :create, params))
      |> redirected_to()
      |> assert_eq("/")
    end

    test "shows an error message and the same qr code and key when an incorrect totp code is entered", %{conn: conn} do
      # secret/0 should not have been called because the same QR code should be shown in case of an invalid totp code
      Test.TOTPMock |> expect(:secret, 0, fn -> Test.TOTPStub.secret() end)

      params = %{"mfa" => %{"totp" => "000000"}}

      conn
      |> Session.put_multifactor_auth_secret({Test.TOTPStub.raw_secret(), Test.TOTPStub.encoded_secret()})
      |> post(Routes.user_multifactor_auth_path(conn, :create, params))
      |> Pages.form_errors()
      |> assert_eq(["The six-digit code was incorrect"])
    end
  end
end
