defmodule EpicenterWeb.InvestigationNotesSectionTest do
  use EpicenterWeb.ConnCase, async: true

  import EpicenterWeb.LiveComponent.Helpers
  import Phoenix.LiveViewTest

  alias Epicenter.Cases.InvestigationNote
  alias Epicenter.Accounts.User
  alias EpicenterWeb.InvestigationNotesSection
  alias EpicenterWeb.Test.Components

  @notes [
    %InvestigationNote{
      id: "test-note-id-a",
      text: "second note",
      author_id: "test-author-id",
      author: %User{id: "test-author-id", name: "Alice Testuser"},
      inserted_at: ~U[2020-10-31 10:30:00Z]
    },
    %InvestigationNote{
      id: "test-note-id-b",
      text: "first note",
      author_id: "test-author-id",
      author: %User{id: "test-author-id", name: "Alice Testuser"},
      inserted_at: ~U[2020-10-31 10:30:00Z]
    }
  ]

  def default_notes(), do: @notes

  defmodule TestLiveView do
    use EpicenterWeb, :live_view

    import EpicenterWeb.LiveComponent.Helpers
    import EpicenterWeb.LiveHelpers, only: [assign_defaults: 1, noreply: 1]

    alias Epicenter.Accounts
    alias EpicenterWeb.InvestigationNotesSection
    alias EpicenterWeb.InvestigationNotesSectionTest

    def mount(_params, _session, socket) do
      {:ok,
       socket
       |> assign_defaults()
       |> assign(
         current_user: %Accounts.User{},
         current_user_id: "test-current-user-id",
         notes: InvestigationNotesSectionTest.default_notes(),
         on_add_note: &Function.identity/1,
         on_delete_note: &Function.identity/1
       )}
    end

    def render(assigns) do
      ~H"""
      <%= l_component(
        InvestigationNotesSection,
        "displays-a-notes-section",
        notes: @notes,
        is_editable: true,
        current_user_id: @current_user_id,
        on_add_note: @on_add_note,
        on_delete_note: @on_delete_note
      ) %>
      """
    end

    def handle_info({:assigns, new_assigns}, socket) do
      socket |> assign(new_assigns) |> noreply()
    end
  end

  describe "initial render" do
    test "renders notes", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestLiveView)

      assert [%{text: "first note"}, %{text: "second note"}] = Components.InvestigationNote.note_content(view)
    end
  end

  describe "adding a note" do
    test "calls the on_add callback, passing along the new note attrs", %{conn: conn} do
      pid = self()
      on_add_note = fn note_attrs -> send(pid, {:received_on_add, note_attrs}) end
      {:ok, view, _html} = live_isolated(conn, TestLiveView)

      send(view.pid, {:assigns, on_add_note: on_add_note})

      view
      |> element("form.investigation-note-form")
      |> render_submit(%{"form_field_data" => %{"text" => "A new note"}})

      assert_receive {:received_on_add, %{text: "A new note"}}
    end
  end

  describe "deleting a note" do
    test "calls the on_delete callback with the note to delete", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestLiveView)

      note_to_delete = List.first(@notes)
      pid = self()
      on_delete_note = fn note -> send(pid, {:received_on_delete, note}) end

      send(
        view.pid,
        {:assigns, on_delete_note: on_delete_note, current_user_id: note_to_delete.author_id}
      )

      assert :ok = Components.InvestigationNote.delete_note(view, note_to_delete.id)
      assert_receive {:received_on_delete, ^note_to_delete}
    end
  end
end
