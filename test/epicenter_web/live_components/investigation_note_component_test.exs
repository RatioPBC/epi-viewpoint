defmodule EpicenterWeb.InvestigationNoteComponentTest do
  use EpicenterWeb.ConnCase, async: true

  import EpicenterWeb.LiveComponent.Helpers
  import Phoenix.LiveViewTest

  alias Epicenter.Accounts.User
  alias Epicenter.Cases.InvestigationNote
  alias EpicenterWeb.InvestigationNoteComponent
  alias EpicenterWeb.Test.Components

  defmodule TestLiveView do
    alias EpicenterWeb.InvestigationNoteComponent

    @note %InvestigationNote{
      id: "test-note-id",
      text: "Hello, this is a note",
      author_id: "test-author-id",
      author: %User{id: "test-author-id", name: "Alice Testuser"},
      inserted_at: ~U[2020-10-31 10:30:00Z]
    }

    use EpicenterWeb.Test.ComponentEmbeddingLiveView,
      default_assigns: [
        current_user: %User{},
        current_user_id: "test-user-id",
        note: @note,
        on_delete: &Function.identity/1
      ]

    def default_note, do: @note

    def render(assigns) do
      ~H"""
      <.live_component
        module = {InvestigationNoteComponent}
        id="renders-a-note"
        note={@note}
        is_editable={true}
        current_user_id={@current_user_id}
        on_delete={@on_delete}
      />
      """
    end
  end

  describe "initial render" do
    test "renders a note", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestLiveView)

      assert [
               %{
                 id: "test-note-id",
                 text: "Hello, this is a note",
                 author: "Alice Testuser",
                 date: "10/31/2020"
               }
             ] = Components.InvestigationNote.note_content(view)
    end

    test "does not show a delete link if the current user is not the author of the note", %{
      conn: conn
    } do
      {:ok, view, _html} = live_isolated(conn, TestLiveView)
      send(view.pid, {:assigns, current_user_id: "not-the-author-id"})

      assert :delete_button_not_found = Components.InvestigationNote.delete_note(view, "test-note-id")
    end

    test "allows the current user to click a delete link if they are the author of the note", %{
      conn: conn
    } do
      {:ok, view, _html} = live_isolated(conn, TestLiveView)
      send(view.pid, {:assigns, current_user_id: TestLiveView.default_note().author_id})

      assert :ok = Components.InvestigationNote.delete_note(view, "test-note-id")
    end
  end

  describe "deleting a note" do
    test "calls the on_delete callback with the note to delete", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestLiveView)

      pid = self()
      on_delete = fn note -> send(pid, {:received_on_delete, note}) end

      send(
        view.pid,
        {:assigns, on_delete: on_delete, current_user_id: TestLiveView.default_note().author_id}
      )

      assert :ok = Components.InvestigationNote.delete_note(view, "test-note-id")
      default_note = TestLiveView.default_note()
      assert_receive {:received_on_delete, ^default_note}
    end
  end
end
