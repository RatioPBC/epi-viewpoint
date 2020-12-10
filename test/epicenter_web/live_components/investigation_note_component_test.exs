defmodule EpicenterWeb.InvestigationNoteComponentTest do
  use EpicenterWeb.ConnCase, async: true

  import EpicenterWeb.LiveComponent.Helpers
  import Phoenix.LiveViewTest

  alias Epicenter.Accounts.User
  alias Epicenter.Cases.InvestigationNote
  alias Epicenter.Test
  alias EpicenterWeb.InvestigationNoteComponent
  alias EpicenterWeb.Test.Pages

  @note %InvestigationNote{
    id: "test-note-id",
    text: "Hello, this is a note",
    author_id: "test-author-id",
    author: %User{id: "test-author-id", name: "Alice Testuser"},
    inserted_at: ~U[2020-10-31 10:30:00Z]
  }

  def default_note, do: @note

  defmodule TestLiveView do
    use EpicenterWeb, :live_view

    import EpicenterWeb.LiveComponent.Helpers
    import EpicenterWeb.LiveHelpers, only: [noreply: 1]

    alias EpicenterWeb.InvestigationNoteComponent
    alias EpicenterWeb.InvestigationNoteComponentTest

    def mount(_params, _session, socket) do
      {:ok, socket |> assign(current_user_id: "test-user-id", note: InvestigationNoteComponentTest.default_note(), on_delete: &Function.identity/1)}
    end

    def render(assigns) do
      ~H"""
      = component(@socket,
            InvestigationNoteComponent,
            "renders-a-note",
            note: @note,
            current_user_id: @current_user_id,
            on_delete: @on_delete)
      """
    end

    def handle_info({:assigns, new_assigns}, socket) do
      socket |> assign(new_assigns) |> noreply()
    end
  end

  describe "initial render" do
    test "renders a note", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestLiveView)

      [note_details] =
        view
        |> render()
        |> Test.Html.parse()
        |> Test.Html.all("[data-role=investigation-note]", fn note_el ->
          id = Test.Html.attr(note_el, "data-note-id") |> List.first()
          text = Test.Html.find(note_el, "[data-role=investigation-note-text]") |> Test.Html.text()
          author = Test.Html.find(note_el, "[data-role=investigation-note-author]") |> Test.Html.text()
          date = Test.Html.find(note_el, "[data-role=investigation-note-date]") |> Test.Html.text()
          %{id: id, text: text, author: author, date: date}
        end)

      # TODO: something like this?
      #        |> Test.Html.find("[data-role=investigation-note]")
      #        |> note_attributes()

      assert %{
               id: "test-note-id",
               text: "Hello, this is a note",
               author: "Alice Testuser",
               date: "10/31/2020"
             } = note_details
    end

    test "does not show a delete link if the current user is not the author of the note", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestLiveView)
      send(view.pid, {:assigns, current_user_id: "not-the-author-id"})

      assert :delete_button_not_found = Pages.Profile.remove_note(view, "test-note-id")
    end

    test "allows the current user to click a delete link if they are the author of the note", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestLiveView)
      send(view.pid, {:assigns, current_user_id: @note.author_id})

      assert :ok = Pages.Profile.remove_note(view, "test-note-id")
    end
  end

  describe "deleting a note" do
    test "calls the on_delete callback with the note to delete", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestLiveView)

      pid = self()
      on_delete = fn note -> send(pid, {:received_on_delete, note}) end
      send(view.pid, {:assigns, on_delete: on_delete, current_user_id: @note.author_id})

      assert :ok = Pages.Profile.remove_note(view, "test-note-id")
      assert_receive {:received_on_delete, @note}
    end
  end
end
