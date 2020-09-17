defmodule EpicenterWeb.ProfileEditLive do
  use EpicenterWeb, :live_view

  alias Epicenter.Cases
  alias EpicenterWeb.Session

  def mount(%{"id" => id}, _session, socket) do
    person = %{Cases.get_person(id) | originator: Session.get_current_user()}
    changeset = Cases.change_person(person, %{})

    {:ok, assign(socket, person: person, changeset: changeset)}
  end

  def handle_event("save", %{"person" => person_params}, socket) do
    case Cases.update_person(socket.assigns.person, person_params) do
      {:ok, person} ->
        {:noreply, socket |> push_redirect(to: Routes.profile_path(socket, EpicenterWeb.ProfileLive, person))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("validate", %{"person" => person_params}, socket) do
    socket
    |> assign(changeset: Cases.change_person(socket.assigns.person, person_params) |> Map.put(:action, :validate))
    |> noreply()
  end

  defp noreply(socket),
    do: {:noreply, socket}
end
