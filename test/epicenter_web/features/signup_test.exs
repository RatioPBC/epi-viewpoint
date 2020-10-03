defmodule EpicenterWeb.Features.SignupTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Release
  alias EpicenterWeb.Test.Pages

  test "an account is made for a user and then they log in", %{conn: conn} do
    #
    # a user is created manually, and a reset-password URL is created
    #
    {:ok, url} = Release.create_user("Test User", "user@example.com", puts: &Function.identity/1)

    #
    # the user visits the reset-password URL, changes their password, and logs in
    #
    conn
    |> Pages.ResetPassword.visit(url)
    |> Pages.ResetPassword.change_password("password123")
    |> Pages.Login.log_in("user@example.com", "password123")
    |> Pages.People.assert_here()
    |> Pages.assert_current_user("Test User")
  end
end
