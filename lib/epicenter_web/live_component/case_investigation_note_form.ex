defmodule EpicenterWeb.CaseInvestigationNoteForm do
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
      field :text, :string
    end

    @required_attrs ~w{case_investigation_id text}a

    def changeset(case_investigation, params) do
      %__MODULE__{
        case_investigation_id: case_investigation.id
      }
      |> cast(params, @required_attrs)
      |> validate_required(@required_attrs)
    end

    def case_investigation_note_attrs(%Ecto.Changeset{} = form_changeset, author_id) do
      with {:ok, form_field_data} <- apply_action(form_changeset, :create) do
        {:ok, %{case_investigation_id: form_field_data.case_investigation_id, text: form_field_data.text, author_id: author_id}}
      else
        other -> other
      end
    end
  end

  def update(assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign(changeset: socket.assigns[:changeset] || empty_note(assigns))}
  end

  defp empty_note(assigns) do
    FormFieldData.changeset(%{id: assigns.case_investigation_id}, %{})
  end

  def render(assigns) do
    ~H"""
    = form_for @changeset, "#", [data: [role: "note-form", "confirm-navigation": confirmation_prompt(@changeset)], phx_change: "change_note", phx_submit: "save_note", phx_target: @myself], fn f ->
      = add_note_form_builder(f)
    """
  end

  def handle_event("change_note", %{"form_field_data" => params}, socket) do
    socket
    |> assign(changeset: FormFieldData.changeset(%{id: socket.assigns.case_investigation_id}, params))
    |> noreply()
  end

  def handle_event("save_note", %{"form_field_data" => params}, socket) do
    with %Ecto.Changeset{} = form_changeset <- FormFieldData.changeset(%{id: socket.assigns.case_investigation_id}, params),
         {:form, {:ok, case_investigation_note_attrs}} <-
           {:form, FormFieldData.case_investigation_note_attrs(form_changeset, socket.assigns.current_user_id)},
         {:note, {:ok, _note}} <-
           {:note,
            Cases.create_case_investigation_note(
              {case_investigation_note_attrs,
               %AuditLog.Meta{
                 author_id: socket.assigns.current_user_id,
                 reason_action: AuditLog.Revision.create_case_investigation_note_action(),
                 reason_event: AuditLog.Revision.profile_case_investigation_note_submission_event()
               }}
            )} do
      Cases.broadcast_case_investigation_updated(socket.assigns.case_investigation_id)
      socket |> assign(changeset: empty_note(socket.assigns)) |> noreply()
    else
      {:form, {:error, changeset}} ->
        socket |> assign(changeset: changeset) |> noreply()

      _ ->
        socket |> noreply()
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
    |> Form.line(&Form.hidden_field(&1, :case_investigation_id))
    |> textarea.()
    |> Form.safe()
  end
end
