defmodule EpicenterWeb.DemographicsEditLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_defaults: 2, assign_page_title: 2, noreply: 1, ok: 1]

  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias Epicenter.Extra
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

  def handle_event(
        "form-change",
        %{"person" => %{"ethnicity" => %{"major" => "hispanic_latinx_or_spanish_origin", "detailed" => _detailed}} = person_params},
        socket
      ) do
    changeset = socket.assigns.person |> Cases.change_person(person_params)
    socket |> assign(changeset: changeset) |> noreply()
  end

  def handle_event("form-change", %{"person" => %{"ethnicity" => ethnicity} = _person_params}, socket) do
    params = Euclid.Extra.Map.deep_atomize_keys(ethnicity)

    changeset =
      Ecto.Changeset.delete_change(socket.assigns.changeset, :ethnicity)
      |> Ecto.Changeset.put_change(:ethnicity, params)

    socket |> assign(changeset: changeset) |> noreply()
  end

  def handle_event("form-change", %{"person" => person_params}, socket) do
    changeset = socket.assigns.person |> Cases.change_person(person_params)
    socket |> assign(changeset: changeset) |> noreply()
  end

  def handle_event("form-change", _, socket), do: noreply(socket)

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
      {"not_hispanic_latinx_or_spanish_origin", "Not Hispanic, Latino/a, or Spanish origin"},
      {"hispanic_latinx_or_spanish_origin", "Hispanic, Latino/a, or Spanish origin"}
    ]
  end

  @detailed_ethnicity_mapping %{
    "hispanic_latinx_or_spanish_origin" => [
      {"mexican_mexican_american_chicanx", "Mexican, Mexican American, Chicano/a"},
      {"puerto_rican", "Puerto Rican"},
      {"cuban", "Cuban"},
      {"another_hispanic_latinx_or_spanish_origin", "Another Hispanic, Latino/a or Spanish origin"}
    ]
  }

  def detailed_ethnicity_options(major_ethnicity),
    do: @detailed_ethnicity_mapping[major_ethnicity] || []

  def detailed_ethnicity_checked(%Ecto.Changeset{} = changeset, detailed_ethnicity),
    do: changeset |> Extra.Changeset.get_field_from_changeset(:ethnicity) |> detailed_ethnicity_checked(detailed_ethnicity)

  def detailed_ethnicity_checked(%{detailed: nil}, _detailed_ethnicity),
    do: false

  def detailed_ethnicity_checked(%{detailed: detailed_ethnicities}, detailed_ethnicity),
    do: detailed_ethnicity in detailed_ethnicities

  def detailed_ethnicity_checked(_, _),
    do: false

  def gender_identity_is_checked(),
    do: nil
end
