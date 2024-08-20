defmodule EpicenterWeb.CaseInvestigationIsolationOrderLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.ConfirmationModal, only: [confirmation_prompt: 1]
  import EpicenterWeb.IconView, only: [back_icon: 0]

  import EpicenterWeb.LiveHelpers,
    only: [assign_defaults: 1, assign_page_title: 2, authenticate_user: 2, noreply: 1, ok: 1]

  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias Epicenter.DateParser
  alias Epicenter.Validation
  alias EpicenterWeb.Form
  alias EpicenterWeb.Format

  defmodule IsolationOrderForm do
    use Ecto.Schema

    import Ecto.Changeset

    @required_attrs ~w{clearance_order_sent_on order_sent_on}a
    @optional_attrs ~w{}a
    @primary_key false
    embedded_schema do
      field :clearance_order_sent_on, :string
      field :order_sent_on, :string
    end

    def changeset(case_investigation, attrs) do
      %IsolationOrderForm{
        clearance_order_sent_on: Format.date(case_investigation.isolation_clearance_order_sent_on),
        order_sent_on: Format.date(case_investigation.isolation_order_sent_on)
      }
      |> cast(attrs, @required_attrs ++ @optional_attrs)
      |> Validation.validate_date(:clearance_order_sent_on)
      |> Validation.validate_date(:order_sent_on)
    end

    def form_changeset_to_model_attrs(%Ecto.Changeset{} = form_changeset) do
      case apply_action(form_changeset, :create) do
        {:ok, form} ->
          {:ok,
           %{
             isolation_clearance_order_sent_on: form |> Map.get(:clearance_order_sent_on) |> DateParser.parse_mm_dd_yyyy!(),
             isolation_order_sent_on: form |> Map.get(:order_sent_on) |> DateParser.parse_mm_dd_yyyy!()
           }}

        other ->
          other
      end
    end
  end

  def handle_event("change", %{"isolation_order_form" => params}, socket) do
    new_changeset = IsolationOrderForm.changeset(socket.assigns.case_investigation, params)
    socket |> assign(confirmation_prompt: confirmation_prompt(new_changeset), form_changeset: new_changeset) |> noreply()
  end

  def handle_event("save", %{"isolation_order_form" => params}, socket) do
    with %Ecto.Changeset{} = form_changeset <- IsolationOrderForm.changeset(socket.assigns.case_investigation, params),
         {:form, {:ok, model_attrs}} <- {:form, IsolationOrderForm.form_changeset_to_model_attrs(form_changeset)},
         {:case_investigation, {:ok, _case_investigation}} <- {:case_investigation, update_case_investigation(socket, model_attrs)} do
      socket
      |> push_navigate(to: ~p"/people/#{socket.assigns.case_investigation.person}/#case-investigations")
      |> noreply()
    else
      {:form, {:error, %Ecto.Changeset{valid?: false} = form_changeset}} ->
        socket |> assign(:form_changeset, form_changeset) |> noreply()
    end
  end

  def isolation_order_form_builder(form, _case_investigation) do
    Form.new(form)
    |> Form.line(&Form.date_field(&1, :order_sent_on, "Date isolation order sent", span: 3))
    |> Form.line(&Form.date_field(&1, :clearance_order_sent_on, "Date isolation clearance order sent", span: 3))
    |> Form.line(&Form.save_button(&1))
    |> Form.safe()
  end

  def mount(%{"id" => case_investigation_id}, session, socket) do
    socket = socket |> authenticate_user(session)
    case_investigation = Cases.get_case_investigation(case_investigation_id, socket.assigns.current_user) |> Cases.preload_person()

    socket
    |> assign_defaults()
    |> assign(:case_investigation, case_investigation)
    |> assign(:confirmation_prompt, nil)
    |> assign(:form_changeset, IsolationOrderForm.changeset(case_investigation, %{}))
    |> assign_page_title(" Case Investigation Isolation Order")
    |> ok()
  end

  # # #

  defp update_case_investigation(socket, params) do
    Cases.update_case_investigation(
      socket.assigns.case_investigation,
      {params,
       %AuditLog.Meta{
         author_id: socket.assigns.current_user.id,
         reason_action: AuditLog.Revision.update_case_investigation_action(),
         reason_event: AuditLog.Revision.edit_case_investigation_isolation_order_event()
       }}
    )
  end
end
