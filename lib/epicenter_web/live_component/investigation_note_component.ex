defmodule EpicenterWeb.InvestigationNoteComponent do
  use EpicenterWeb, :live_component

  import EpicenterWeb.LiveHelpers, only: [noreply: 1]

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
          a.investigation-note-delete-link href="#" data-confirm="Remove your note?" phx-click="delete-note" data-role="delete-note" phx-target=@myself Delete
    """
  end

  def handle_event("delete-note", _params, socket) do
    socket.assigns.on_delete.(socket.assigns.note)
    socket |> noreply()
  end
end
