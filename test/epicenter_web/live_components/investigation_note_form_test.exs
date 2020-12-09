defmodule EpicenterWeb.InvestigationNoteFormTest do
  use EpicenterWeb.ConnCase, async: true

  import EpicenterWeb.LiveComponent.Helpers
  import Phoenix.LiveViewTest

  alias EpicenterWeb.InvestigationNoteForm

  defmodule TestLiveView do
    use EpicenterWeb, :live_view

    import EpicenterWeb.LiveComponent.Helpers
    #    import EpicenterWeb.LiveHelpers, only: [assign_page_title: 2, ok: 1, noreply: 1]

    alias EpicenterWeb.InvestigationNoteForm

    #    def mount(params, session, socket) do
    #      connect_params = get_connect_params(socket)
    #      on_add = Map.get(session, "on_add") || fn _note -> nil end
    #      {:ok, socket |> assign(assigns) |> assign(on_add: on_add)}
    #    end

    def render(assigns) do
      ~H"""
      = component(@socket,
            InvestigationNoteForm,
            "renders-a-form",
            case_investigation_id: nil,
            exposure_id: nil,
            current_user_id: "author-1",
            on_add: fn _note -> nil end)
      """
    end
  end

  describe "initial render" do
    test "renders a form", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestLiveView)

      assert has_element?(view, "form")
    end

    test "does not render a save button", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestLiveView)

      refute has_element?(view, "button[data-role='save-button']")
    end
  end

  describe "typing text into the text area" do
    test "shows the save button", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestLiveView)
      view |> element("form") |> render_change(%{"form_field_data" => %{"text" => "A new note"}})

      assert has_element?(view, "button[data-role='save-button']")
    end
  end

  @tag :skip
  describe "submitting the form" do
    test "invokes the on_add callback", %{conn: conn} do
      on_add = fn _note -> send(self(), :received_on_add) end

      {:ok, view, _html} = live_isolated(conn, TestLiveView, connect_params: %{"on_add" => on_add})
      view |> element("form") |> render_submit(%{"form_field_data" => %{"text" => "A new note"}})

      assert_received :received_on_add
    end
  end
end
