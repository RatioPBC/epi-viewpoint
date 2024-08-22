defmodule EpiViewpointWeb.AdminAuthorizationTest do
  use EpiViewpointWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias EpiViewpoint.Accounts
  alias EpiViewpoint.AccountsFixtures
  alias EpiViewpoint.Test
  alias EpiViewpointWeb.UserLive
  alias EpiViewpointWeb.UsersLive

  defp visit_isolated(user_fixture, live_view, conn),
    do: live_isolated(conn, live_view, session: %{"user_token" => user_fixture |> Accounts.generate_user_session_token() |> Map.get(:token)})

  def assert_on_page({:ok, _view, html}, page),
    do: html |> Test.Html.parse() |> Test.Html.all("[data-page]", attr: "data-page") |> assert_eq([page])

  def assert_redirected_to_root({:error, {:redirect, %{to: "/"}}}),
    do: :ok

  def assert_redirected_to_root(other),
    do: raise("expected to be redirected to root; got #{inspect(other)}")

  test "only allows confirmed admins", %{conn: conn} do
    unprivileged_user = AccountsFixtures.user_fixture(%{tid: "snooper"})
    unconfirmed_admin = AccountsFixtures.unconfirmed_user_fixture(%{tid: "unconfirmed", admin: true})
    confirmed_admin = AccountsFixtures.user_fixture(%{tid: "confirmed", admin: true})

    unprivileged_user |> visit_isolated(UserLive, conn) |> assert_redirected_to_root()
    unprivileged_user |> visit_isolated(UsersLive, conn) |> assert_redirected_to_root()
    unconfirmed_admin |> visit_isolated(UserLive, conn) |> assert_redirected_to_root()
    unconfirmed_admin |> visit_isolated(UsersLive, conn) |> assert_redirected_to_root()
    confirmed_admin |> visit_isolated(UserLive, conn) |> assert_on_page("user")
    confirmed_admin |> visit_isolated(UsersLive, conn) |> assert_on_page("users")
  end
end
