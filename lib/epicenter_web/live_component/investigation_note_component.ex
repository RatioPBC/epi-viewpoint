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
    <div class="investigation-note" data-note-id={"#{@note.id}"} data-role="investigation-note">
      <div class="investigation-note-header">
        <span class="investigation-note-author" data-role="investigation-note-author">
          <%= @note.author.name %>
        </span><span data-role="investigation-note-date"><%= Format.date(@note.inserted_at) %></span>
      </div>
      <div class="investigation-note-text" data-role="investigation-note-text"><%= @note.text %></div>
      <%= if @note.author_id == @current_user_id && @is_editable do %>
        <div>
          <a
            class="investigation-note-delete-link"
            data-confirm="Remove your note?"
            data-role="delete-note"
            href="#"
            phx-click="delete-note"
            phx-target={"#{@myself}"}
          >
            Delete
          </a>
        </div>
      <% end %>
    </div>
    """
    |> Map.put(:root, true)
  end

  def handle_event("delete-note", _params, socket) do
    socket.assigns.on_delete.(socket.assigns.note)
    socket |> noreply()
  end
end
