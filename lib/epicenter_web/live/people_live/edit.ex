defmodule EpicenterWeb.PeopleLive.Edit do
  use EpicenterWeb, :live_view

  alias Epicenter.Cases

  def mount(%{"id" => id}, _session, socket) do
    person = Cases.get_person(id)
    changeset = Cases.change_person(person, %{})

    {:ok, assign(socket, person: person, changeset: changeset)}
  end

  def handle_event("save", %{"person" => person_params}, socket) do
    case Cases.update_person(socket.assigns.person, person_params) do
      {:ok, person} ->
        {:noreply, socket |> push_redirect(to: Routes.people_show_path(socket, :show, person))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
