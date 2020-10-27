defmodule EpicenterWeb.DemographicsEditLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.IconView, only: [back_icon: 0]
  import EpicenterWeb.LiveHelpers, only: [authenticate_user: 2, assign_page_title: 2, noreply: 1, ok: 1]
  import EpicenterWeb.ConfirmationModal, only: [abandon_changes_confirmation_text: 0]

  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias Epicenter.Extra
  alias Epicenter.Format

  def mount(%{"id" => id}, session, socket) do
    socket = socket |> authenticate_user(session)
    person = Cases.get_person(id) |> Cases.preload_demographics()
    demographic = Cases.Person.coalesce_demographics(person) |> Map.put(:__struct__, Cases.Demographic)
    changeset = demographic |> Ecto.Changeset.cast(%{}, [])

    socket
    |> assign_page_title("#{Format.person(person)} (edit)")
    |> assign(changeset: changeset)
    |> assign(demographic: demographic)
    |> assign(person: person)
    |> assign(confirmation_prompt: nil)
    |> ok()
  end

  def handle_event("form-change", %{"demographic" => form_params} = form_state, socket) do
    new_ethnicity = get_or_update_ethnicity_from_changeset(socket.assigns.changeset, form_state)

    new_changeset =
      socket.assigns.demographic
      |> Cases.Demographic.changeset(form_params)

    # TODO unchecking the last gender box doesn't work unless you add this commented code back
    #    new_changeset =
    #      case person_params do
    #        %{"gender_identity" => _} -> new_changeset
    #        _ -> Map.put(new_changeset, "gender_identity", [])
    #      end

    new_changeset =
      case form_params do
        %{"ethnicity" => _ethnicity} ->
          new_changeset
          |> Ecto.Changeset.put_change(:ethnicity, Euclid.Extra.Map.deep_atomize_keys(new_ethnicity))

        _ ->
          new_changeset
      end

    socket |> assign(:changeset, new_changeset) |> assign_confirmation_prompt |> noreply()
  end

  def handle_event("submit", %{"demographic" => demographic_params} = _params, socket) do
    non_form_demographics = socket.assigns.person.demographics |> Enum.reject(&(&1.source == "form")) |> Euclid.Extra.Enum.pluck([:id])
    form_demographic = socket.assigns.person.demographics |> Enum.find(&(&1.source == "form"))

    person_params = %{
      "id" => socket.assigns.person.id,
      "demographics" =>
        non_form_demographics ++
          [
            %{
              "id" => if(form_demographic, do: form_demographic.id, else: nil),
              "source" => "form"
            }
            |> Map.merge(demographic_params)
          ]
    }

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

  defp get_or_update_ethnicity_from_changeset(changeset, form_params) do
    old_form_state = expected_person_params_from_changeset(changeset)

    old_major_ethnicity = old_form_state && old_form_state.major
    new_major_ethnicity = form_params["demographic"]["ethnicity"]["major"]

    old_detailed_ethnicity = old_form_state && old_form_state.detailed
    new_detailed_ethnicity = form_params["demographic"]["ethnicity"]["detailed"]

    cond do
      old_major_ethnicity != new_major_ethnicity and old_major_ethnicity == "hispanic_latinx_or_spanish_origin" ->
        %{major: new_major_ethnicity, detailed: %{}}

      old_detailed_ethnicity != new_detailed_ethnicity and Euclid.Exists.present?(new_detailed_ethnicity) ->
        %{major: "hispanic_latinx_or_spanish_origin", detailed: new_detailed_ethnicity}

      true ->
        form_params["demographic"]["ethnicity"]
    end
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

  def gender_identity_checked(changeset, gender_identity_option) do
    case changeset |> Extra.Changeset.get_field_from_changeset(:gender_identity) do
      nil -> false
      gender_list -> gender_identity_option in gender_list
    end
  end

  def gender_identity_is_checked(),
    do: nil

  defp expected_person_params_from_changeset(changeset),
    do: changeset |> Extra.Changeset.get_field_from_changeset(:ethnicity)

  defp assign_confirmation_prompt(socket) do
    prompt =
      case socket.assigns.changeset do
        nil -> nil
        _changeset -> abandon_changes_confirmation_text()
      end

    socket |> assign(confirmation_prompt: prompt)
  end
end
