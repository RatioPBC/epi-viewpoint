defmodule EpicenterWeb.AssignmentSelector do
  use EpicenterWeb, :live_component

  import EpicenterWeb.LiveHelpers, only: [noreply: 1]

  def render(assigns) do
    ~H"""
    <form data-disabled={@disabled} id="assignment-form" phx-change="form-change" phx-target={@myself}>
      <div id="user-list">
        <span id="assign-to-label">Assign to</span>
        <div id="select-wrapper">
          <select data-role="users" disabled={@disabled} name="user">
            <option></option>
            <option value="-unassigned-">Unassigned</option>
            <%= for user <- @users do %>
              <option value={user.id}><%= user.name %></option>
            <% end %>
          </select>
        </div>
      </div>
      <div id="assignment-dropdown-tooltip">Select people below, then assign them to a user</div>
    </form>
    """
    |> Map.put(:root, true)
  end

  def handle_event("form-change", %{"user" => "-unassigned-"}, socket),
    do: handle_event("form-change", %{"user" => nil}, socket)

  def handle_event("form-change", %{"user" => user_id}, socket) do
    socket.assigns.on_assignee_selected.(user_id)

    socket |> noreply()
  end
end
