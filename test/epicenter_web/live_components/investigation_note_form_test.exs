defmodule EpicenterWeb.InvestigationNoteFormTest do
  use EpicenterWeb.ConnCase, async: true

  import EpicenterWeb.LiveComponent.Helpers
  import Phoenix.LiveViewTest

  alias EpicenterWeb.InvestigationNoteForm
  alias EpicenterWeb.Test.Pages

  defmodule TestLiveView do
    use EpicenterWeb, :live_view

    import EpicenterWeb.LiveComponent.Helpers
    import EpicenterWeb.LiveHelpers, only: [noreply: 1]

    alias EpicenterWeb.InvestigationNoteForm

    def mount(_params, _session, socket) do
      {:ok, socket |> assign(subject_id: nil, on_add: &Function.identity/1)}
    end

    def render(assigns) do
      ~H"""
      = component(@socket,
            InvestigationNoteForm,
            "renders-a-form",
            subject_id: @subject_id,
            current_user_id: "test-user",
            on_add: @on_add)
      """
    end

    def handle_info({:assigns, new_assigns}, socket) do
      socket |> assign(new_assigns) |> noreply()
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

  describe "submitting the form" do
    test "calls the on_add callback, passing the note attrs", %{conn: conn} do
      pid = self()
      on_add = fn note_attrs -> send(pid, {:received_on_add, note_attrs}) end
      {:ok, view, _html} = live_isolated(conn, TestLiveView)

      send(view.pid, {:assigns, on_add: on_add})

      view |> element("form") |> render_submit(%{"form_field_data" => %{"text" => "A new note"}})

      assert_receive {:received_on_add, %{author_id: "test-user", subject_id: nil, text: "A new note"}}
    end

    test "includes the subject_id when provided", %{conn: conn} do
      pid = self()
      on_add = fn note_attrs -> send(pid, {:received_on_add, note_attrs}) end
      {:ok, view, _html} = live_isolated(conn, TestLiveView)

      send(view.pid, {:assigns, on_add: on_add, subject_id: "test-subject-id", subject_id_attr_name: "exposure_id"})

      view |> element("form") |> render_submit(%{"form_field_data" => %{"text" => "A new note"}})

      assert_receive {:received_on_add, %{author_id: "test-user", subject_id: "test-subject-id", text: "A new note"}}
    end

    test "clears the form", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestLiveView)

      view |> element("form") |> render_change(%{"form_field_data" => %{"text" => "A new note"}})
      %{"form_field_data[text]" => text} = Pages.form_state(view)
      assert text |> Euclid.Exists.present?()

      view |> element("form") |> render_submit(%{"form_field_data" => %{"text" => "A new note"}})
      %{"form_field_data[text]" => text} = Pages.form_state(view)
      assert text |> Euclid.Exists.blank?()
    end
  end

  describe "validation" do
    test "shows an error when there is no text", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestLiveView)
      view |> element("form") |> render_submit(%{"form_field_data" => %{"text" => ""}})

      assert has_element?(view, ".invalid-feedback[phx-feedback-for='form_field_data_text']")
    end

    test "does not call on_add when there is no text", %{conn: conn} do
      pid = self()
      on_add = fn note_attrs -> send(pid, {:received_on_add, note_attrs}) end

      {:ok, view, _html} = live_isolated(conn, TestLiveView)
      send(view.pid, {:assigns, on_add: on_add})
      view |> element("form") |> render_submit(%{"form_field_data" => %{"text" => ""}})

      refute_receive {:received_on_add, _}
    end
  end
end
