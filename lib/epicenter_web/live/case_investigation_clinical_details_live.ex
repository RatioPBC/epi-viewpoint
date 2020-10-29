defmodule EpicenterWeb.CaseInvestigationClinicalDetailsLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_page_title: 2, ok: 1]

  alias Epicenter.Cases.CaseInvestigation
  alias EpicenterWeb.Form

  defmodule ClinicalDetailsForm do
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :clinical_status, :string
    end

    @required_attrs ~w{}a
    @optional_attrs ~w{clinical_status}a

    def changeset(%CaseInvestigation{} = case_investigation) do
      case_investigation |> case_investigation_attrs |> changeset()
    end

    def changeset(attrs) do
      %ClinicalDetailsForm{}
      |> cast(attrs, @required_attrs ++ @optional_attrs)
    end

    def case_investigation_attrs(%CaseInvestigation{} = case_investigation) do
      case_investigation
      |> Map.from_struct()
    end
  end

  def mount(%{"id" => _id}, _session, socket) do
    socket
    |> assign_page_title(" Case Investigation Clinical Details")
    |> assign(:form_changeset, ClinicalDetailsForm.changeset(%CaseInvestigation{}))
    |> ok()
  end

  def clinical_details_form_builder(form) do
    Form.new(form)
    |> Form.line(&Form.radio_button_list(&1, :clinical_status, "Clinical Status", clinical_statuses()))
    |> Form.safe()
  end

  defp clinical_statuses() do
    [
      {"Unknown", "unknown"},
      {"Symptomatic", "symptomatic"},
      {"Asymptomatic", "asymptomatic"}
    ]
  end
end
