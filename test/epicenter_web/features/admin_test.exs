defmodule EpicenterWeb.Features.AdminTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Accounts
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  @admin Test.Fixtures.admin()

  setup :register_and_log_in_user

  test "admins can see the admin nav", %{conn: conn, user: user} do
    user |> Accounts.update_user(%{admin: true}, Test.Fixtures.audit_meta(@admin))

    conn
    |> get("/people")
    |> Pages.Navigation.assert_has_menu_item("Admin")
  end

  test "non-admins do not see the admin nav", %{conn: conn} do
    conn
    |> get("/people")
    |> Pages.Navigation.refute_has_menu_item("Admin")
  end

  test "admin can administer users", %{conn: conn, user: user} do
    user |> Accounts.update_user(%{admin: true}, Test.Fixtures.audit_meta(@admin))

    Test.Fixtures.user_attrs(@admin, "billy")
    |> Accounts.register_user!()
    |> Accounts.update_disabled(:disabled, Test.Fixtures.audit_meta(@admin))

    conn
    |> Pages.Users.visit()
    |> Pages.Users.assert_here()
    |> Pages.Users.assert_users([
      ["Name", "Email", "Type", "Status"],
      ["billy", "billy@example.com", "Member", "Inactive"],
      ["fixture admin", "admin@example.com", "Admin", "Active"],
      ["user", "user@example.com", "Admin", "Active"]
    ])

    # todo: click "new user"

    conn
    |> Pages.User.visit()
    |> Pages.submit_and_follow_redirect(conn, "#user-form",
      user_form: %{"name" => "New User", "email" => "new@example.com", "type" => "member", "status" => "active"}
    )
    |> Pages.Users.assert_here()
    |> Pages.Users.assert_users([
      ["Name", "Email", "Type", "Status"],
      ["billy", "billy@example.com", "Member", "Inactive"],
      ["fixture admin", "admin@example.com", "Admin", "Active"],
      ["New User", "new@example.com", "Member", "Active"],
      ["user", "user@example.com", "Admin", "Active"]
    ])
  end

  test "non-admins cannot administer users", %{conn: conn} do
    conn
    |> get("/admin/users")
    |> Pages.ForbiddenError.assert_here()
  end
end
