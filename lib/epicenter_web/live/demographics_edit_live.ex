defmodule EpicenterWeb.DemographicsEditLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.ConfirmationModal, only: [abandon_changes_confirmation_text: 0]
  import EpicenterWeb.IconView, only: [back_icon: 0]
  import EpicenterWeb.LiveHelpers, only: [authenticate_user: 2, assign_page_title: 2, noreply: 1, ok: 1]

  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias Epicenter.Cases.Demographic
  alias EpicenterWeb.Format
  alias EpicenterWeb.Form
  alias EpicenterWeb.Forms.DemographicForm
  alias EpicenterWeb.Multiselect

  @specs %{
    gender_identity: [
      {:radio, "Unknown", "unknown"},
      {:radio, "Declined to answer", "declined_to_answer"},
      {:checkbox, "Female", "female"},
      {:checkbox, "Transgender woman/trans woman/male-to-female (MTF)", "transgender_woman"},
      {:checkbox, "Male", "male"},
      {:checkbox, "Transgender man/trans man/female-to-male (FTM)", "transgender_man"},
      {:checkbox, "Genderqueer/gender nonconforming neither exclusively male nor female", "gender_nonconforming"},
      {:other_checkbox, "Additional gender category (or other)", ""}
    ],
    sex_at_birth: [
      {:radio, "Unknown", "unknown"},
      {:radio, "Declined to answer", "declined_to_answer"},
      {:radio, "Female", "female"},
      {:radio, "Male", "male"},
      {:radio, "Intersex", "intersex"}
    ],
    ethnicity: [
      {:radio, "Unknown", "unknown"},
      {:radio, "Declined to answer", "declined_to_answer"},
      {:radio, "Not Hispanic, Latino/a, or Spanish origin", "not_hispanic_latinx_or_spanish_origin"},
      {:radio, "Hispanic, Latino/a, or Spanish origin", "hispanic_latinx_or_spanish_origin",
       [
         {:checkbox, "Mexican, Mexican American, Chicano/a", "mexican_mexican_american_chicanx"},
         {:checkbox, "Puerto Rican", "puerto_rican"},
         {:checkbox, "Cuban", "cuban"},
         {:other_checkbox, "Another Hispanic, Latino/a or Spanish origin", ""}
       ]}
    ],
    race: [
      {:radio, "Unknown", "unknown"},
      {:radio, "Declined to answer", "declined_to_answer"},
      {:checkbox, "White", "white"},
      {:checkbox, "Black or African American", "black_or_african_american"},
      {:checkbox, "American Indian or Alaska Native", "american_indian_or_alaska_native"},
      {:checkbox, "Asian", "asian",
       [
         {:checkbox, "Asian Indian", "asian_indian"},
         {:checkbox, "Chinese", "chinese"},
         {:checkbox, "Filipino", "filipino"},
         {:checkbox, "Japanese", "japanese"},
         {:checkbox, "Korean", "korean"},
         {:checkbox, "Vietnamese", "vietnamese"},
         {:other_checkbox, "Other Asian", ""}
       ]},
      {:checkbox, "Native Hawaiian or Other Pacific Islander", "native_hawaiian_or_other_pacific_islander",
       [
         {:checkbox, "Native Hawaiian", "native_hawaiian"},
         {:checkbox, "Guamanian or Chamorro", "guamanian_or_chamorro"},
         {:checkbox, "Samoan", "samoan"},
         {:other_checkbox, "Other Pacific Islander", ""}
       ]},
      {:other_checkbox, "Other", ""}
    ],
    marital_status: [
      {:radio, "Unknown", "unknown"},
      {:radio, "Single", "single"},
      {:radio, "Married", "married"}
    ],
    employment: [
      {:radio, "Unknown", "unknown"},
      {:radio, "Not employed", "not_employed"},
      {:radio, "Part time", "part_time"},
      {:radio, "Full time", "full_time"}
    ]
  }

  def mount(%{"id" => id}, session, socket) do
    socket = socket |> authenticate_user(session)
    person = Cases.get_person(id) |> Cases.preload_demographics()
    demographic = Cases.Person.coalesce_demographics(person) |> Map.put(:__struct__, Cases.Demographic)

    socket
    |> assign_page_title("#{Format.person(person)} (edit)")
    |> assign_form_changeset(DemographicForm.model_to_form_changeset(demographic))
    |> assign(person: person)
    |> assign(confirmation_prompt: nil)
    |> ok()
  end

  def handle_event("form-change", params, socket) do
    form_changeset =
      Multiselect.Changeset.conform(
        socket.assigns.form_changeset,
        Map.get(params, "demographic_form", %{}) |> DemographicForm.attrs_to_form_changeset(),
        params,
        "demographic_form",
        @specs
      )

    socket
    |> assign(confirmation_prompt: abandon_changes_confirmation_text())
    |> assign_form_changeset(form_changeset)
    |> noreply()
  end

  def handle_event("save", params, socket) do
    demographic_params = Map.get(params, "demographic_form", %{})
    person = socket.assigns.person
    current_user = socket.assigns.current_user

    with %Ecto.Changeset{} = form_changeset <- DemographicForm.attrs_to_form_changeset(demographic_params),
         {:form, {:ok, model_attrs}} <- {:form, DemographicForm.form_changeset_to_model_attrs(form_changeset)},
         {:model, {:ok, _model}} <- {:model, create_or_update_model(model_attrs, person, current_user)} do
      socket |> redirect_to_profile_page() |> noreply()
    else
      {:form, {:error, %Ecto.Changeset{valid?: false} = form_changeset}} ->
        socket |> assign_form_changeset(form_changeset) |> noreply()

      {:model, {:error, _}} ->
        socket |> assign_form_changeset(DemographicForm.attrs_to_form_changeset(params), "An unexpected error occurred") |> noreply()
    end
  end

  def create_or_update_model(attrs, person, author) do
    audit_meta = %Epicenter.AuditLog.Meta{
      author_id: author.id,
      reason_event: AuditLog.Revision.edit_profile_demographics_event()
    }

    attrs = attrs |> Map.put(:person_id, person.id)

    case Cases.get_demographic(person, source: :form) do
      nil ->
        audit_meta = %{audit_meta | reason_action: AuditLog.Revision.insert_demographics_action()}
        {:ok, _demographic} = Cases.create_demographic({attrs, audit_meta})

      %Demographic{} = demographic ->
        audit_meta = %{audit_meta | reason_action: AuditLog.Revision.update_demographics_action()}
        {:ok, _demographic} = Cases.update_demographic(demographic, {attrs, audit_meta})
    end
  end

  defp assign_form_changeset(socket, %Ecto.Changeset{valid?: false} = changeset),
    do: socket |> assign_form_changeset(changeset, "Check the errors above")

  defp assign_form_changeset(socket, %Ecto.Changeset{} = changeset, form_error \\ nil) do
    socket |> assign(form_changeset: changeset, form_error: form_error)
  end

  defp redirect_to_profile_page(socket) do
    person = socket.assigns.person
    socket |> push_redirect(to: "#{Routes.profile_path(socket, EpicenterWeb.ProfileLive, person)}#demographics-data")
  end

  # # #

  def form_builder(form) do
    Form.new(form)
    |> Form.line(&Form.multiselect(&1, :gender_identity, "Gender identity", @specs.gender_identity, span: 8))
    |> Form.line(&Form.multiselect(&1, :sex_at_birth, "Sex at birth", @specs.sex_at_birth, span: 8))
    |> Form.line(&Form.multiselect(&1, :ethnicity, "Ethnicity", @specs.ethnicity, span: 8))
    |> Form.line(&Form.multiselect(&1, :race, "Race", @specs.race, span: 8))
    |> Form.line(&Form.multiselect(&1, :marital_status, "Marital status", @specs.marital_status, span: 8))
    |> Form.line(&Form.multiselect(&1, :employment, "Employment status", @specs.employment, span: 8))
    |> Form.line(&Form.text_field(&1, :occupation, "Occupation", span: 6))
    |> Form.line(&Form.textarea_field(&1, :notes, "Notes", span: 6))
    |> Form.line(&Form.footer(&1, nil, span: 8, sticky: true))
    |> Form.safe()
  end
end
