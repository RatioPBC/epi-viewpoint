defmodule EpicenterWeb.UserLoginsLiveTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Accounts
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  setup :log_in_admin

  test "table renders login history", %{conn: conn} do
    #    navigate to user logins page
    #    assert that we see a login history row for admin

    #     = Test.Fixtures.user_attrs(admin_user, "surveilled_user", %{}) |> Accounts.register_user!()
    surveilled_user = Test.Fixtures.user_attrs(Test.Fixtures.admin(), "assignee") |> Accounts.register_user!()

    user_token = Accounts.generate_user_session_token(surveilled_user)
    user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.88 Safari/537.36"

    {:ok, _} = Accounts.create_login(%{session_id: user_token.id, user_agent: user_agent, user_id: surveilled_user.id})

    [login] = Accounts.list_logins(surveilled_user.id)

    Pages.UserLogins.visit(conn, surveilled_user)
    |> Pages.UserLogins.assert_here()
    |> Pages.UserLogins.assert_table_contents([
      ["Timestamp", "OS", "Browser", "Session ID"],
      #        ["8/11/2020, 10:34am ET", "Mac", "Chrome", login.session_id]
      ["*", "*", "*", login.session_id]
    ])
  end
end
