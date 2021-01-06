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
    |> Accounts.update_user(%{disabled: true}, Test.Fixtures.audit_meta(@admin))

    conn
    |> Pages.Users.visit()
    |> Pages.Users.assert_here()
    |> Pages.Users.assert_users([
      ["Name", "Email", "Type", "Status", "Audit trail"],
      ["billy", "billy@example.com", "Member", "Inactive", "View"],
      ["fixture admin", "admin@example.com", "Admin", "Active", "View"],
      ["user", "user@example.com", "Admin", "Active", "View"]
    ])
    |> Pages.Users.click_add_user(conn)
    |> Pages.User.assert_here()
    |> Pages.submit_and_follow_redirect(conn, "#user-form",
      user_form: %{"name" => "New User", "email" => "new@example.com", "type" => "member", "status" => "active"}
    )
    |> Pages.Users.assert_here()
    |> Pages.Users.assert_users([
      ["Name", "Email", "Type", "Status", "Audit trail"],
      ["billy", "billy@example.com", "Member", "Inactive", "View"],
      ["fixture admin", "admin@example.com", "Admin", "Active", "View"],
      ["New User", "new@example.com", "Member", "Active", "View"],
      ["user", "user@example.com", "Admin", "Active", "View"]
    ])
    |> Pages.Users.click_view_audit_trail(conn, "user")
    |> Pages.UserLogins.assert_here()
    |> Pages.UserLogins.assert_page_header("Audit trail for user")
  end

  test "non-admins cannot administer users", %{conn: conn} do
    conn
    |> get("/admin/users")
    |> Pages.ForbiddenError.assert_here()
  end
end
