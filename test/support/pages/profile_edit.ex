defmodule EpicenterWeb.Test.Pages.ProfileEdit do
  import Phoenix.LiveViewTest

  alias Epicenter.Cases.Person
  alias EpicenterWeb.Test.LiveViewAssertions
  alias EpicenterWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  def visit(%Plug.Conn{} = conn, %Person{id: person_id}) do
    conn |> Pages.visit("/people/#{person_id}/edit")
  end

  def assert_validation_messages(%View{} = view, expected_messages) do
    view |> render() |> LiveViewAssertions.assert_validation_messages(expected_messages)
    view
  end

  def click_add_email_button(%View{} = view) do
    view |> render_click("add-email")
    view
  end

  def submit(%View{} = view, person_params) do
    view
    |> form("#profile-form", person: person_params)
    |> render_submit()

    view |> Pages.ProfileEdit.assert_validation_messages(%{})
  end

  def submit_and_follow_redirect(%View{} = view, conn, person_params) do
    {:ok, view, _} =
      view
      |> form("#profile-form", person: person_params)
      |> render_submit()
      |> Pages.follow_liveview_redirect(conn)

    view
  end
end
