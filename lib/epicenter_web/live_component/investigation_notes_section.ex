defmodule EpicenterWeb.InvestigationNotesSection do
  use EpicenterWeb, :live_component

  alias EpicenterWeb.InvestigationNoteComponent
  alias EpicenterWeb.InvestigationNoteForm

  def render(assigns) do
    ~H"""
    .investigation-notes-section
      h3.additional_notes Additional Notes
      = component(@socket,
        InvestigationNoteForm,
        @subject.id <> "note form",
        current_user_id: @current_user_id,
        on_add: @on_add_note )
      = for note <- @notes |> Enum.reverse() do
        = component(@socket, InvestigationNoteComponent, note.id <> "note", note: note, current_user_id: @current_user_id, on_delete: @on_delete_note)
    """
  end
end
