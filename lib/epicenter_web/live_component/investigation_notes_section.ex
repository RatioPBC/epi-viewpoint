defmodule EpicenterWeb.InvestigationNotesSection do
  use EpicenterWeb, :live_component

  alias EpicenterWeb.InvestigationNoteComponent
  alias EpicenterWeb.InvestigationNoteForm

  def render(assigns) do
    # TODO: we should have a nice way of automatically providing @key or @id regardless of whether the component is
    #       stateless or stateful, to prevent regressions.
    ~M"""
    .investigation-notes-section
      h3.additional_notes Additional Notes
      = if @is_editable do
        = component(@socket,
          InvestigationNoteForm,
          @key <> "note form",
          current_user_id: @current_user_id,
          on_add: @on_add_note )
      = for note <- @notes |> Enum.reverse() do
        = component(@socket, InvestigationNoteComponent, note.id <> "note", note: note, is_editable: @is_editable, current_user_id: @current_user_id, on_delete: @on_delete_note)
    """
  end
end
