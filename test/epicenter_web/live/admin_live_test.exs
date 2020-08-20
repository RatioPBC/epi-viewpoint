defmodule EpicenterWeb.AdminLiveTest do
  use EpicenterWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Epicenter.Cases.Import

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/admin")
    assert disconnected_html =~ "Admin"
    assert render(page_live) =~ "Admin"
  end

  test "mounts with person and lab result count", %{conn: conn} do
    {:ok, page_live, _html} = live(conn, "/admin")

    assert_role_text(page_live, "person-count", "0")
    assert_role_text(page_live, "lab-result-count", "0")

    import_info = %Import.ImportInfo{
      imported_person_count: 1,
      imported_lab_result_count: 2,
      total_person_count: 3,
      total_lab_result_count: 4
    }

    Phoenix.PubSub.broadcast(Epicenter.PubSub, "cases", {:import, import_info})

    assert_role_text(page_live, "person-count", "3")
    assert_role_text(page_live, "lab-result-count", "4")
  end
end
