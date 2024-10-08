defmodule EpiViewpointWeb.UserResetPasswordControllerTest do
  use EpiViewpointWeb.ConnCase, async: true

  alias EpiViewpoint.Accounts
  alias EpiViewpoint.Repo
  alias Phoenix.Flash
  import EpiViewpoint.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "GET /users/reset-password" do
    @tag :skip
    test "renders the reset password page", %{conn: conn} do
      # path = Routes.user_reset_password_path(conn, :new)
      path = "/"
      conn = get(conn, path)
      response = html_response(conn, 200)
      assert response =~ "Reset your password"
    end
  end

  describe "POST /users/reset-password" do
    @tag :skip
    @tag :capture_log
    test "sends a new reset password token", %{conn: conn, user: user} do
      # path = Routes.user_reset_password_path(conn, :create)
      path = "/"
      conn = post(conn, path, %{"user" => %{"email" => user.email}})

      assert redirected_to(conn) == "/"
      assert Flash.get(conn.assigns.flash, :info) =~ "An email with instructions was sent"
      assert Repo.get_by!(Accounts.UserToken, user_id: user.id).context == "reset_password"
    end

    @tag :skip
    test "does not send reset password token if email is invalid", %{conn: conn} do
      # path = Routes.user_reset_password_path(conn, :create)
      path = "/"
      conn = post(conn, path, %{"user" => %{"email" => "unknown@example.com"}})

      assert redirected_to(conn) == "/"
      assert Flash.get(conn.assigns.flash, :info) =~ "An email with instructions was sent"
      assert Repo.all(Accounts.UserToken) == []
    end
  end

  describe "GET /users/reset-password/:token" do
    setup %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_reset_password_instructions(user, url)
        end)

      %{token: token}
    end

    test "renders reset password", %{conn: conn, token: token} do
      conn = get(conn, ~p"/users/reset-password/#{token}")
      assert html_response(conn, 200) =~ "Set your password"
    end

    test "does not render reset password with invalid token", %{conn: conn} do
      conn = get(conn, ~p"/users/reset-password/oops")
      assert redirected_to(conn) == "/"
      assert Flash.get(conn.assigns.flash, :error) =~ "Reset password link is invalid or it has expired"
    end
  end

  describe "PUT /users/reset-password/:token" do
    setup %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_reset_password_instructions(user, url)
        end)

      %{token: token}
    end

    test "resets password once", %{conn: conn, user: user, token: token} do
      conn =
        put(conn, ~p"/users/reset-password/#{token}", %{
          "user" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(conn) == ~p"/users/login"
      refute get_session(conn, :user_token)
      assert Flash.get(conn.assigns.flash, :info) =~ "Password reset successfully"
      assert Accounts.get_user(email: user.email, password: "new valid password")
    end

    test "does not reset password on invalid data", %{conn: conn, token: token} do
      conn =
        put(conn, ~p"/users/reset-password/#{token}", %{
          "user" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(conn, 200)
      assert response =~ "Set your password"
      assert response =~ "must be between 10 and 80 characters"
      assert response =~ "does not match password"
    end

    test "does not reset password with invalid token", %{conn: conn} do
      conn = put(conn, ~p"/users/reset-password/oops")
      assert redirected_to(conn) == "/"
      assert Flash.get(conn.assigns.flash, :error) =~ "Reset password link is invalid or it has expired"
    end
  end
end
