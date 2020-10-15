defmodule EpicenterWeb.DemographicsEditLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_defaults: 2, assign_page_title: 2, noreply: 1, ok: 1]

  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias Epicenter.Format

  def mount(%{"id" => id}, session, socket) do
    socket = socket |> assign_defaults(session)
    person = %{Cases.get_person(id) | originator: socket.assigns.current_user.id}
    changeset = person |> Cases.change_person(%{}) |> hard_code_gender_identity()

    socket
    |> assign_page_title("#{Format.person(person)} (edit)")
    |> assign(changeset: changeset)
    |> assign(person: person)
    |> ok()
  end

  def handle_event("submit", %{"person" => person_params} = _params, socket) do
    socket.assigns.person
    |> Cases.update_person(
      {person_params,
       %AuditLog.Meta{
         author_id: socket.assigns.current_user.id,
         reason_action: AuditLog.Revision.update_profile_action(),
         reason_event: AuditLog.Revision.edit_profile_saved_event()
       }}
    )
    |> case do
      {:ok, person} ->
        socket
        |> push_redirect(to: Routes.profile_path(socket, EpicenterWeb.ProfileLive, person))
        |> noreply()

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp hard_code_gender_identity(%{data: data} = changeset) do
    %{changeset | data: %{data | gender_identity: ["Female"]}}
  end

  def gender_identity_options() do
    [
      "Declined to answer",
      "Female",
      "Transgender woman/trans woman/male-to-female (MTF)",
      "Male",
      "Transgender man/trans man/female-to-male (FTM)",
      "Genderqueer/gender nonconforming neither exclusively male nor female",
      "Additional gender category (or other)"
    ]
  end

  def major_ethnicity_options() do
    [
      {"unknown", "Unknown"},
      {"declined_to_answer", "Declined to answer"},
      {"not_hispanic", "Not Hispanic, Latino/a, or Spanish origin"},
      {"hispanic", "Hispanic, Latino/a, or Spanish origin"}
    ]
  end

  def gender_identity_is_checked() do
  end
end
