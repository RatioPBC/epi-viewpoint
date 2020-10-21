defmodule EpicenterWeb.UsersLiveTest do
  use EpicenterWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Epicenter.Accounts
  alias Epicenter.AccountsFixtures

  describe "attempting to visit as an unprivileged user" do
    test "redirects to the home path", %{conn: conn} do
      token =
        AccountsFixtures.user_fixture(%{tid: "snooper"})
        |> Accounts.generate_user_session_token()

      session = %{"user_token" => token}

      assert {:error, {:redirect, %{to: "/"}}} = live_isolated(conn, EpicenterWeb.UsersLive, session: session)
    end
  end

  describe "attempting to visit as an unconfirmed admin" do
    test "redirects to the home path", %{conn: conn} do
      token =
        AccountsFixtures.unconfirmed_user_fixture(%{tid: "administrator", admin: true})
        |> Accounts.generate_user_session_token()

      session = %{"user_token" => token}

      assert {:error, {:redirect, %{to: "/"}}} = live_isolated(conn, EpicenterWeb.UsersLive, session: session)
    end
  end

  describe "attempting to visit as a confirmed admin" do
    test "does not redirect", %{conn: conn} do
      token =
        AccountsFixtures.user_fixture(%{tid: "administrator", admin: true})
        |> Accounts.generate_user_session_token()

      session = %{"user_token" => token}

      {:ok, _, html} = live_isolated(conn, EpicenterWeb.UsersLive, session: session)

      assert html =~ "Users"
    end
  end
end
