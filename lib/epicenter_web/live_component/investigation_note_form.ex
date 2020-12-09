defmodule EpicenterWeb.InvestigationNoteForm do
  use EpicenterWeb, :live_component

  import EpicenterWeb.ConfirmationModal, only: [abandon_changes_confirmation_text: 0]
  import EpicenterWeb.LiveHelpers, only: [noreply: 1]

  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias EpicenterWeb.Form

  defmodule FormFieldData do
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :case_investigation_id, :binary_id
      field :exposure_id, :binary_id
      field :text, :string
    end

    @optional_attrs ~w{case_investigation_id exposure_id}a
    @required_attrs ~w{text}a

    def changeset(case_investigation, exposure, params) do
      %__MODULE__{
        case_investigation_id: case_investigation.id,
        exposure_id: exposure.id
      }
      |> cast(params, @optional_attrs ++ @required_attrs)
      |> validate_required(@required_attrs)
    end

    def investigation_note_attrs(%Ecto.Changeset{} = form_changeset, author_id) do
      with {:ok, form_field_data} <- apply_action(form_changeset, :create) do
        {:ok,
         %{
           author_id: author_id,
           case_investigation_id: form_field_data.case_investigation_id,
           exposure_id: form_field_data.exposure_id,
           text: form_field_data.text
         }}
      else
        other -> other
      end
    end
  end

  def update(assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign(changeset: socket.assigns[:changeset] || empty_note(assigns))}
  end

  defp empty_note(assigns) do
    FormFieldData.changeset(%{id: assigns.case_investigation_id}, %{id: assigns.exposure_id}, %{})
  end

  def render(assigns) do
    ~H"""
    = form_for @changeset, "#", [data: [role: "note-form", "confirm-navigation": confirmation_prompt(@changeset)], phx_change: "change_note", phx_submit: "save_note", phx_target: @myself], fn f ->
      = add_note_form_builder(f)
    """
  end

  def handle_event("change_note", %{"form_field_data" => params}, socket) do
    socket
    |> assign(changeset: FormFieldData.changeset(%{id: socket.assigns.case_investigation_id}, %{id: socket.assigns.exposure_id}, params))
    |> noreply()
  end

  def handle_event("save_note", %{"form_field_data" => params}, socket) do
    with %Ecto.Changeset{} = form_changeset <-
           FormFieldData.changeset(%{id: socket.assigns.case_investigation_id}, %{id: socket.assigns.exposure_id}, params),
         {reason_action, reason_event} <- audit_log_event_names(form_changeset),
         {:form, {:ok, investigation_note_attrs}} <-
           {:form, FormFieldData.investigation_note_attrs(form_changeset, socket.assigns.current_user_id)},
         {:note, {:ok, note}} <-
           {:note,
            Cases.create_investigation_note(
              {investigation_note_attrs,
               %AuditLog.Meta{
                 author_id: socket.assigns.current_user_id,
                 reason_action: reason_action,
                 reason_event: reason_event
               }}
            )} do
      socket.assigns.on_add.(note)
      socket |> assign(changeset: empty_note(socket.assigns)) |> noreply()
    else
      {:form, {:error, changeset}} ->
        socket |> assign(changeset: changeset) |> noreply()

      _ ->
        socket |> noreply()
    end
  end

  defp audit_log_event_names(form_changeset) do
    if form_changeset.data.case_investigation_id != nil do
      {
        AuditLog.Revision.create_case_investigation_note_action(),
        AuditLog.Revision.profile_case_investigation_note_submission_event()
      }
    else
      {
        AuditLog.Revision.create_exposure_note_action(),
        AuditLog.Revision.profile_exposure_note_submission_event()
      }
    end
  end

  def confirmation_prompt(changeset) do
    if changeset.changes == %{}, do: nil, else: abandon_changes_confirmation_text()
  end

  # # #

  defp add_note_form_builder(form) do
    textarea = fn form ->
      text = form.f.source |> Ecto.Changeset.fetch_field!(:text)

      if Euclid.Exists.present?(text) do
        form
        |> Form.line(&Form.textarea_field(&1, :text, "", span: 6, placeholder: "Add note..."))
        |> Form.line(&Form.save_button(&1))
      else
        form
        |> Form.line(&Form.textarea_field(&1, :text, "", rows: 1, span: 6, placeholder: "Add note..."))
      end
    end

    Form.new(form)
    #    |> Form.line(&Form.hidden_field(&1, :case_investigation_id))
    |> textarea.()
    |> Form.safe()
  end
end
