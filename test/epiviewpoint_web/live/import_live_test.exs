defmodule EpiViewpointWeb.ImportLiveTest do
  use EpiViewpointWeb.ConnCase, async: true

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias EpiViewpoint.Accounts
  alias EpiViewpoint.Test
  alias EpiViewpointWeb.Test.Pages

  setup :register_and_log_in_user
  @admin Test.Fixtures.admin()

  test "view is accesible to admins", %{conn: conn, user: user} do
    Accounts.update_user(user, %{admin: true}, Test.Fixtures.audit_meta(@admin))

    Pages.ImportLive.visit(conn)
    |> Pages.ImportLive.upload_button_visible?()
    |> assert()
  end

  test "view is not accessible to non-admins", %{conn: conn, user: user} do
    Accounts.update_user(user, %{admin: false}, Test.Fixtures.audit_meta(@admin))

    assert {:error, {:redirect, _flash}} = live(conn, "/import/start")
  end
end
