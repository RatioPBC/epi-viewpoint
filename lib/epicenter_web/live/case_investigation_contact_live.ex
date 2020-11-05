defmodule EpicenterWeb.CaseInvestigationContactLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.IconView, only: [back_icon: 0]
  import EpicenterWeb.LiveHelpers, only: [authenticate_user: 2, assign_page_title: 2, noreply: 1, ok: 1]

  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias Epicenter.Cases.Exposure
  alias EpicenterWeb.Form

  defmodule ContactForm do
    use Ecto.Schema

    import Ecto.Changeset

    alias Epicenter.Cases.Exposure
    alias Epicenter.DateParser
    alias Epicenter.Validation

    embedded_schema do
      field :first_name, :string
      field :last_name, :string
      field :relationship_to_case, :string
      field :same_household, :boolean
      field :under_18, :boolean
      field :phone, :string
      field :preferred_language, :string
      field :most_recent_date_together, :string
    end

    def changeset(%Exposure{} = exposure, attrs) do
      %__MODULE__{
        first_name: "",
        last_name: "",
        phone: ""
      }
      |> cast(attrs, [
        :first_name,
        :last_name,
        :relationship_to_case,
        :same_household,
        :under_18,
        :phone,
        :preferred_language,
        :most_recent_date_together
      ])
      |> validate_required([
        :first_name,
        :last_name,
        :relationship_to_case,
        :same_household,
        :under_18,
        :most_recent_date_together
      ])
      |> Validation.validate_date(:most_recent_date_together)
    end

    def contact_params(%Ecto.Changeset{} = formdata) do
      with {:ok, data} <- apply_action(formdata, :insert) do
        {:ok,
         %{
           most_recent_date_together: DateParser.parse_mm_dd_yyyy!(data.most_recent_date_together),
           relationship_to_case: data.relationship_to_case,
           under_18: data.under_18,
           household_member: data.same_household,
           exposed_person: %{
             demographics: [
               %{source: "form", first_name: data.first_name, last_name: data.last_name}
             ]
           }
         }}
      end
    end
  end

  def mount(%{"id" => case_investigation_id}, session, socket) do
    case_investigation = case_investigation_id |> Cases.get_case_investigation() |> Cases.preload_person()

    socket
    |> authenticate_user(session)
    |> assign_page_title("Case Investigation Contact")
    |> assign(:changeset, ContactForm.changeset(%Exposure{}, %{}))
    |> assign(:case_investigation, case_investigation)
    |> ok()
  end

  def handle_event("save", %{"contact_form" => params}, socket) do
    with {:form, {:ok, data}} <- {:form, ContactForm.changeset(%Exposure{}, params) |> ContactForm.contact_params()},
         data = data |> Map.put(:exposing_case_id, socket.assigns.case_investigation.id),
         {:ok, _} <- create_exposure(data, socket.assigns.current_user) do
      socket
      |> push_redirect(to: "#{Routes.profile_path(socket, EpicenterWeb.ProfileLive, socket.assigns.case_investigation.person)}#case-investigations")
      |> noreply()

      # else
      #   {:form, {:error, changeset}} ->
      #     socket
      #     |> assign(changeset: changeset)
      #     |> noreply()
    end
  end

  defp create_exposure(data, author) do
    Cases.create_exposure(
      {data,
       %Epicenter.AuditLog.Meta{
         author_id: author.id,
         reason_action: AuditLog.Revision.create_contact_action(),
         reason_event: AuditLog.Revision.create_contact_event()
       }}
    )
  end

  def contact_form_builder(form) do
    Form.new(form)
    |> Form.line(fn line ->
      line
      |> Form.text_field(:first_name, "First name")
      |> Form.text_field(:last_name, "Last name")
    end)
    |> Form.line(&Form.text_field(&1, :relationship_to_case, "Relationship to case"))
    |> Form.line(&Form.checkbox_field(&1, :same_household, nil, "This person lives in the same household", span: 8))
    |> Form.line(&Form.checkbox_field(&1, :under_18, "Age", "This person is under 18 years old", span: 8))
    |> Form.line(&Form.text_field(&1, :phone, "Phone"))
    |> Form.line(&Form.date_field(&1, :most_recent_date_together, "Most recent day together"))
    |> Form.line(&Form.save_button(&1))
    |> Form.safe()
  end

  def confirmation_prompt(changeset), do: nil
end
