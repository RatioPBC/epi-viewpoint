defmodule EpicenterWeb.Styleguide.InvestigationNotesSectionLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers,
    only: [assign_defaults: 1, assign_page_title: 2, ok: 1, noreply: 1]

  import EpicenterWeb.LiveComponent.Helpers

  alias Epicenter.Accounts.User
  alias Epicenter.ContactInvestigations.ContactInvestigation
  alias Epicenter.Cases.InvestigationNote
  alias EpicenterWeb.InvestigationNotesSection

  def mount(_params, _session, socket) do
    socket
    |> assign_defaults()
    |> assign(current_user: %User{})
    |> assign_page_title("Styleguide: note")
    |> assign(notes: example_notes())
    |> assign(contact_investigation: %ContactInvestigation{id: "styleguide-contact-investigation"})
    |> ok()
  end

  def render(assigns) do
    ~H"""
    <.live_component
      module = {InvestigationNotesSection}
      id = "styleguide-note-section"
      key = "styleguide-note-section"
      current_user_id = "author-1"
      subject = {@contact_investigation}
      notes = {@notes}
      is_editable = {true}
      on_add_note = {&on_add/1}
      on_delete_note = {&on_delete/1}
    />
    """
    |> Map.put(:root, true)
  end

  def on_add(note_attrs) do
    send(self(), {:on_add, note_attrs})
  end

  def on_delete(note) do
    send(self(), {:on_delete, note})
  end

  def example_notes() do
    [
      %InvestigationNote{
        id: "note-1",
        author: %User{name: "Billy"},
        author_id: "author-1",
        inserted_at: ~U[2020-10-31 10:30:00Z],
        text: "Good note"
      },
      %InvestigationNote{
        id: "note-2",
        author: %User{name: "Alice"},
        author_id: "author-2",
        inserted_at: ~U[2020-10-31 10:30:00Z],
        text: "Better note"
      }
    ]
  end

  def handle_info({:on_add, note_attrs}, socket) do
    socket |> assign(notes: [build_note(note_attrs) | socket.assigns.notes]) |> noreply()
  end

  def handle_info({:on_delete, note}, socket) do
    socket |> assign(notes: List.delete(socket.assigns.notes, note)) |> noreply()
  end

  def handle_event(_event, _params, socket) do
    socket |> noreply()
  end

  def build_note(note_attrs) do
    note_attrs =
      note_attrs
      |> Map.put(:inserted_at, ~U[2020-10-31 10:30:00Z])
      |> Map.put(:author, %User{name: "Billy"})
      |> Map.put(:author_id, "author-1")
      |> Map.put(:id, "fake-note-#{:os.system_time(:millisecond)}")

    struct(InvestigationNote, note_attrs)
  end
end
