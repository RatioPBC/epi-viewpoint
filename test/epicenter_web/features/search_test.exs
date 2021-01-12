defmodule EpicenterWeb.Features.SearchTest do
  use EpicenterWeb.ConnCase, async: true

  import Phoenix.ConnTest

  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  test "users see the seach field in the nav bar", %{conn: conn} do
    conn
    |> get("/people")
    |> Pages.Navigation.assert_has_search_field()
  end
end
