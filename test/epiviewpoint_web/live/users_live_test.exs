defmodule EpiViewpointWeb.UsersLiveTest do
  use EpiViewpointWeb.ConnCase, async: true

  alias EpiViewpoint.Accounts
  alias EpiViewpoint.Accounts.UserToken
  alias EpiViewpoint.Repo
  alias EpiViewpoint.Test
  alias EpiViewpointWeb.Test.Pages

  @admin Test.Fixtures.admin()

  setup :register_and_log_in_user

  describe "when current user is an admin" do
    setup %{user: user} do
      [user: user |> Accounts.update_user(%{admin: true}, Test.Fixtures.audit_meta(@admin))]
    end

    test "shows a list of users", %{conn: conn} do
      Test.Fixtures.user_attrs(@admin, "billy")
      |> Accounts.register_user!()
      |> Accounts.update_user(%{disabled: true}, Test.Fixtures.audit_meta(@admin))

      conn
      |> Pages.Users.visit()
      |> Pages.Users.assert_here()
      |> Pages.Users.assert_users([
        ["Name", "Email", "Type", "Status", "Audit trail", ""],
        ["billy", "billy@example.com", "Member", "Inactive", "View", "Set/reset password"],
        ["fixture admin", "admin@example.com", "Admin", "Active", "View", "Set/reset password"],
        ["user", "user@example.com", "Admin", "Active", "View", "Set/reset password"]
      ])
    end

    test "can generate and display a user reset link", %{conn: conn} do
      Test.Fixtures.user_attrs(@admin, "alice") |> Accounts.register_user!()

      link =
        conn
        |> Pages.Users.visit()
        |> Pages.Users.assert_here()
        |> Pages.Users.click_set_reset_password("alice")
        |> Pages.Users.get_password_reset_link("alice")

      {:ok, token} = link |> URI.parse() |> Map.get(:path) |> String.split("/") |> List.last() |> Base.url_decode64(padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.sent_to == "alice@example.com"
      assert user_token.context == "reset_password"
    end
  end

  describe "when current user is not an admin" do
    test "forbidden", %{conn: conn} do
      conn
      |> get("/admin/users")
      |> Pages.ForbiddenError.assert_here()
    end
  end
end
