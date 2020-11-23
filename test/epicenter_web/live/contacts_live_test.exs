defmodule EpicenterWeb.ContactsLiveTest do
  use EpicenterWeb.ConnCase, async: true

  alias EpicenterWeb.Test.Pages

  setup [:register_and_log_in_user]

  describe "rendering" do
    test "user can visit the contacts page", %{conn: conn} do
      Pages.Contacts.visit(conn)
      |> Pages.Contacts.assert_here()
    end
  end
end
