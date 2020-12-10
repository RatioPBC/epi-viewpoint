defmodule EpicenterWeb.InvestigationNoteComponent do
  use EpicenterWeb, :live_component

  import EpicenterWeb.LiveHelpers, only: [noreply: 1]

  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias EpicenterWeb.Format

  def preload(assigns) do
    notes =
      assigns
      |> Enum.map(fn a -> a.note end)
      |> Cases.preload_author()

    assigns
    |> Enum.with_index()
    |> Enum.map(fn {a, i} -> Map.put(a, :note, Enum.at(notes, i)) end)
  end

  def render(assigns) do
    ~H"""
    .investigation-note data-role="investigation-note" data-note-id=@note.id
      .investigation-note-header
        span.investigation-note-author data-role="investigation-note-author" = @note.author.name
        span data-role="investigation-note-date" = Format.date(@note.inserted_at)
      .investigation-note-text data-role="investigation-note-text" = @note.text
      = if @note.author_id == @current_user_id do
        div
          a.investigation-note-delete-link href="#" data-confirm="Remove your note?" phx-click="remove-note" data-role="remove-note" phx-target=@myself Delete
    """
  end

  def handle_event("remove-note", _params, socket) do
    {:ok, _} =
      Cases.delete_investigation_note(socket.assigns.note, %AuditLog.Meta{
        author_id: socket.assigns.current_user_id,
        reason_action: AuditLog.Revision.remove_case_investigation_note_action(),
        reason_event: AuditLog.Revision.remove_case_investigation_note_event()
      })

    socket.assigns.on_delete.(socket.assigns.note)
    socket |> noreply()
  end
end
