defmodule EpiViewpointWeb.UserSettingsControllerTest do
  use EpiViewpointWeb.ConnCase, async: true
  alias Phoenix.Flash
  alias EpiViewpoint.Accounts
  import EpiViewpoint.AccountsFixtures

  setup :register_and_log_in_user

  describe "GET /users/settings" do
    test "renders settings page", %{conn: conn} do
      conn = get(conn, ~p"/users/settings")
      response = html_response(conn, 200)
      assert response =~ "<h2>Settings</h2>"
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, ~p"/users/settings")
      assert redirected_to(conn) == ~p"/users/login"
    end
  end

  describe "PUT /users/settings/update_password" do
    test "updates the user password and resets tokens", %{conn: conn, user: user} do
      new_password_conn =
        put(conn, ~p"/users/settings/update-password", %{
          "current_password" => valid_user_password(),
          "user" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(new_password_conn) == ~p"/users/settings"
      assert get_session(new_password_conn, :user_token) != get_session(conn, :user_token)
      assert Flash.get(new_password_conn.assigns.flash, :info) =~ "Password updated successfully"
      assert Accounts.get_user(email: user.email, password: "new valid password")
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, ~p"/users/settings/update-password", %{
          "current_password" => "invalid",
          "user" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(old_password_conn, 200)
      assert response =~ "<h2>Settings</h2>"
      assert response =~ "must be between 10 and 80 characters"
      assert response =~ "does not match password"
      assert response =~ "is not valid"

      assert get_session(old_password_conn, :user_token) == get_session(conn, :user_token)
    end
  end
end
