defmodule EpicenterWeb.UserLiveTest do
  use EpicenterWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Epicenter.Test
  alias Epicenter.Accounts
  alias EpicenterWeb.Test.Pages

  @admin Test.Fixtures.admin()

  setup :register_and_log_in_user

  setup %{user: user} do
    {:ok, _} = user |> Accounts.update_user(%{admin: true}, Test.Fixtures.audit_meta(@admin))
    :ok
  end

  test "admins can add admins", %{conn: conn} do
    Pages.User.visit(conn)
    |> Pages.submit_live("#user-form",
      user_form: %{"name" => "New User", "email" => "newadmin@example.com", "type" => "admin", "status" => "active"}
    )

    assert %{name: "New User", email: "newadmin@example.com", admin: true} = Accounts.get_user_by_email("newadmin@example.com")
  end

  test "admins can add disabled users", %{conn: conn} do
    Pages.User.visit(conn)
    |> Pages.submit_live("#user-form",
      user_form: %{"name" => "New User", "email" => "newadmin@example.com", "type" => "member", "status" => "inactive"}
    )

    assert %{name: "New User", email: "newadmin@example.com", disabled: true} = Accounts.get_user_by_email("newadmin@example.com")
  end

  test "users cannot be created with invalid email addresses", %{conn: conn} do
    view =
      Pages.User.visit(conn)
      |> Pages.submit_live("#user-form",
        user_form: %{"name" => "New User", "email" => "an invalid email address", "type" => "member", "status" => "active"}
      )

    assert_validation_messages(render(view), %{"user_form_email" => "must have the @ sign and no spaces"})
  end

  test "all fields are required", %{conn: conn} do
    view =
      Pages.User.visit(conn)
      |> Pages.submit_live("#user-form",
        user_form: %{"name" => "", "email" => "", "type" => "member", "status" => "active"}
      )

    assert_validation_messages(render(view), %{"user_form_email" => "can't be blank", "user_form_name" => "can't be blank"})
  end

  test "must have unique emails", %{conn: conn} do
    view =
      Pages.User.visit(conn)
      |> Pages.submit_live("#user-form",
        user_form: %{"name" => "real name", "email" => @admin.email, "type" => "member", "status" => "active"}
      )
      |> Pages.User.assert_here()

    assert_validation_messages(render(view), %{"user_form_email" => "has already been taken"})
  end
end
