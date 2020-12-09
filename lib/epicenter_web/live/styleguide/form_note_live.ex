defmodule EpicenterWeb.Styleguide.FormNoteLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_page_title: 2, ok: 1, noreply: 1]
  import EpicenterWeb.LiveComponent.Helpers

  alias Epicenter.Accounts.User
  alias Epicenter.Cases.InvestigationNote
  alias EpicenterWeb.InvestigationNoteComponent
  alias EpicenterWeb.InvestigationNoteForm

  def mount(_params, _session, socket) do
    socket
    |> assign_page_title("Styleguide: note")
    |> assign(notes: example_notes())
    |> ok()
  end

  def render(assigns) do
    ~H"""
    <div id="styleguide-note-example">
    = component(@socket,
          InvestigationNoteForm,
          "styleguide-note-form",
          handler: "#styleguide-note-example",
          case_investigation_id: nil,
          exposure_id: nil,
          current_user_id: "author-1",
          on_add: fn _ -> nil end)
        = for note <- @notes do
          = component(@socket, InvestigationNoteComponent, note.id <> "note", note: note, current_user_id: "author-1", on_delete: fn _ -> nil end)
    </div>
    """
  end

  def example_notes() do
    [
      %InvestigationNote{id: "note-1", author: %User{name: "Alice"}, author_id: "author-1", inserted_at: ~U[2020-10-31 10:30:00Z], text: "Good note"},
      %InvestigationNote{
        id: "note-2",
        author: %User{name: "Billy"},
        author_id: "author-2",
        inserted_at: ~U[2020-10-31 10:30:00Z],
        text: "Better note"
      }
    ]
  end

  def handle_event(_event, _params, socket) do
    IO.puts("*** handling the event!")
    socket |> noreply()
  end
end
