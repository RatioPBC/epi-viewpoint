defmodule EpicenterWeb.InvestigationNoteFormTest do
  use EpicenterWeb.ConnCase, async: true

  import EpicenterWeb.LiveComponent.Helpers
  import Phoenix.LiveViewTest

  alias EpicenterWeb.InvestigationNoteForm
  alias EpicenterWeb.Test.Components
  alias EpicenterWeb.Test.Pages

  defmodule TestLiveView do
    use EpicenterWeb.Test.ComponentEmbeddingLiveView, default_assigns: [on_add: &Function.identity/1]
    alias EpicenterWeb.InvestigationNoteForm

    def render(assigns) do
      ~H"""
      = component(@socket,
            InvestigationNoteForm,
            "renders-a-form",
            on_add: @on_add)
      """
    end
  end

  # @tag :focus
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

      Components.InvestigationNoteForm.change_note(view, "A new note")

      assert has_element?(view, "button[data-role='save-button']")
    end
  end

  describe "submitting the form" do
    test "calls the on_add callback, passing the note attrs", %{conn: conn} do
      pid = self()
      on_add = fn note_attrs -> send(pid, {:received_on_add, note_attrs}) end
      {:ok, view, _html} = live_isolated(conn, TestLiveView)

      send(view.pid, {:assigns, on_add: on_add})

      Components.InvestigationNoteForm.submit_new_note(view, "A new note")

      assert_receive {:received_on_add, %{text: "A new note"}}
    end

    test "clears the form", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestLiveView)

      Components.InvestigationNoteForm.change_note(view, "A new note")
      %{"form_field_data[text]" => text} = Pages.form_state(view)
      assert text |> Euclid.Exists.present?()

      Components.InvestigationNoteForm.submit_new_note(view, "A new note")
      %{"form_field_data[text]" => text} = Pages.form_state(view)
      assert text |> Euclid.Exists.blank?()
    end
  end

  describe "validation" do
    test "shows an error when there is no text", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestLiveView)
      Components.InvestigationNoteForm.submit_new_note(view, "")

      assert has_element?(view, ".invalid-feedback[phx-feedback-for='form_field_data_text']")
    end

    test "does not call on_add when there is no text", %{conn: conn} do
      pid = self()
      on_add = fn note_attrs -> send(pid, {:received_on_add, note_attrs}) end

      {:ok, view, _html} = live_isolated(conn, TestLiveView)
      send(view.pid, {:assigns, on_add: on_add})

      Components.InvestigationNoteForm.submit_new_note(view, "")

      refute_receive {:received_on_add, _}
    end
  end
end
