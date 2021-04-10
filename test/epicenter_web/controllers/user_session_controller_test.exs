defmodule EpicenterWeb.UserSessionControllerTest do
  use EpicenterWeb.ConnCase, async: true

  import Epicenter.AccountsFixtures

  alias Epicenter.Accounts
  alias Epicenter.Repo
  alias EpicenterWeb.Test.Pages

  setup do
    %{user: user_fixture()}
  end

  describe "new" do
    test "renders login page", %{conn: conn} do
      conn = get(conn, Routes.user_session_path(conn, :new))
      assert response = html_response(conn, 200)
      Pages.Login.assert_here(response)
    end

    test "redirects if already logged in", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> get(Routes.user_session_path(conn, :new))
      assert redirected_to(conn) == "/"
    end
  end

  describe "new when there are no existing users" do
    setup do
      Accounts.list_users() |> Enum.each(fn user -> Repo.delete(user) end)
      assert Accounts.count_users() == 0

      on_exit(fn ->
        Application.put_env(:epicenter, :initial_user_email, nil)
      end)
    end

    test "when initial_user_email is not set, a message is shown", %{conn: conn} do
      conn = get(conn, Routes.user_session_path(conn, :new))
      assert html_response(conn, 200) =~ "No users have been set up"
    end

    test "when initial_user_email is set, a new initial admin user is created", %{conn: conn} do
      Application.put_env(:epicenter, :initial_user_email, "initial@example.com")

      assert Accounts.count_users() == 0

      conn = get(conn, Routes.user_session_path(conn, :new))

      base_64_url_characters = "a-zA-Z0-9-_"
      at_least_ten_base_64_characters = "[#{base_64_url_characters}]{10,}"
      assert redirected_to(conn) =~ ~r|/users/reset-password/#{at_least_ten_base_64_characters}|

      assert Accounts.count_users() == 1
      [initial_user] = Accounts.list_users()
      assert initial_user.email == "initial@example.com"
      assert initial_user.admin == true
      assert initial_user.hashed_password != nil
    end

    test "when initial_user_email is set but user could not be created, an error is shown", %{conn: conn} do
      Application.put_env(:epicenter, :initial_user_email, "invalid email address")

      conn = get(conn, Routes.user_session_path(conn, :new))
      assert html_response(conn, 200) =~ "Initial user email address “invalid email address” is invalid: must have the @ sign and no spaces"
    end
  end

  describe "create with email and password" do
    test "logs the user in", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{"email" => user.email, "password" => valid_user_password()}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) =~ "/"
    end

    test "emits error message with invalid credentials", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{"email" => user.email, "password" => "invalid_password"}
        })

      response = html_response(conn, 200)
      assert response =~ "Log into your account"
      assert response =~ "Invalid email or password"
    end
  end

  describe "DELETE /users/log_out" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> delete(Routes.user_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :user_token)
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, Routes.user_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :user_token)
    end
  end
end
