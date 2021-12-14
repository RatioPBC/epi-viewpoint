defmodule EpicenterWeb.AssignmentSelector do
  use EpicenterWeb, :live_component

  import EpicenterWeb.LiveHelpers, only: [noreply: 1]

  def render(assigns) do
    ~M"""
    form id="assignment-form" phx-change="form-change" data-disabled=@disabled phx-target=@myself
      #user-list
        span#assign-to-label Assign to
        #select-wrapper
          select name="user" data-role="users" disabled=@disabled
            option value=""
            option value="-unassigned-" Unassigned
            = for user <- @users do
              option value="#{user.id}" #{user.name}
      #assignment-dropdown-tooltip Select people below, then assign them to a user
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
