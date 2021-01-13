defmodule EpicenterWeb.SearchComponentTest do
  use EpicenterWeb.ConnCase, async: true

  import EpicenterWeb.LiveComponent.Helpers
  import Phoenix.LiveViewTest

  alias Epicenter.Accounts.User
  alias EpicenterWeb.SearchComponent

  defmodule TestLiveView do
    alias EpicenterWeb.SearchComponent

    use EpicenterWeb.Test.ComponentEmbeddingLiveView,
      default_assigns: [current_user: %User{}, search_changeset: &Function.identity/1]

    def render(assigns) do
      ~H"""
      = component(@socket,
            SearchComponent,
            "nav-search",
            current_user: @current_user,
            search_changeset: @search_changeset)
      """
    end
  end

  test "renders search", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, TestLiveView)

    assert has_element?(view, "[data-role='app-search']")
  end
end
