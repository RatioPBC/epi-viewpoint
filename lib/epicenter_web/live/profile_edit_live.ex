defmodule EpicenterWeb.ProfileEditLive do
  use EpicenterWeb, :live_view

  alias Epicenter.Cases
  alias Epicenter.DateParser
  alias Epicenter.Extra
  alias EpicenterWeb.Session

  def mount(%{"id" => id}, _session, socket) do
    person = %{Cases.get_person(id) | originator: Session.get_current_user()}
    changeset = Cases.change_person(person, %{})

    {:ok, assign(socket, person: person, changeset: human_readable(changeset))}
  end

  def handle_event("save", %{"person" => person_params}, socket) do
    person_params = clean_up_dates(person_params)

    case Cases.update_person(socket.assigns.person, person_params) do
      {:ok, person} ->
        {:noreply, socket |> push_redirect(to: Routes.profile_path(socket, EpicenterWeb.ProfileLive, person))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("validate", %{"person" => person_params}, socket) do
    person_params = clean_up_dates(person_params)
    updated_person_changeset = Cases.change_person(socket.assigns.person, person_params)

    socket
    |> assign(changeset: updated_person_changeset |> human_readable() |> Map.put(:action, :validate))
    |> noreply()
  end

  # replace human readable dates with Date objects
  defp clean_up_dates(person_params) do
    case DateParser.parse_mm_dd_yyyy(person_params["dob"]) do
      {:ok, date} -> %{person_params | "dob" => date}
      {:error, _} -> person_params
    end
  end

  # Change date formats and give more specific error messages
  defp human_readable(changeset) do
    changeset =
      case Ecto.Changeset.fetch_field(changeset, :dob) do
        {:error} -> changeset
        {_, dob_value} -> Ecto.Changeset.put_change(changeset, :dob, Extra.Date.render(dob_value))
      end

    changeset =
      update_in(
        changeset.errors,
        &Enum.map(&1, fn
          {:dob, {_, opts}} -> {:dob, {"please enter dates as mm/dd/yyyy", opts}}
          {_key, _error} = tuple -> tuple
        end)
      )
    changeset
  end

  defp noreply(socket),
    do: {:noreply, socket}
end
