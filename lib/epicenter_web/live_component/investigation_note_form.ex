defmodule EpicenterWeb.InvestigationNoteForm do
  use EpicenterWeb, :live_component

  import EpicenterWeb.ConfirmationModal, only: [abandon_changes_confirmation_text: 0]
  import EpicenterWeb.LiveHelpers, only: [noreply: 1]

  alias EpicenterWeb.Form

  defmodule FormFieldData do
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :text, :string
    end

    @required_attrs ~w{text}a

    def changeset(params) do
      %__MODULE__{}
      |> cast(params, @required_attrs)
      |> validate_required(@required_attrs)
    end

    def investigation_note_attrs(%Ecto.Changeset{} = form_changeset) do
      with {:ok, form_field_data} <- apply_action(form_changeset, :create) do
        {:ok,
         %{
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

  defp empty_note(_assigns) do
    FormFieldData.changeset(%{})
  end

  def render(assigns) do
    ~H"""
    = form_for @changeset, "#", [class: "investigation-note-form", data: [role: "note-form", "confirm-navigation": confirmation_prompt(@changeset)], phx_change: "change_note", phx_submit: "save_note", phx_target: @myself], fn f ->
      = add_note_form_builder(f)
    """
  end

  def handle_event("change_note", %{"form_field_data" => params}, socket) do
    socket
    |> assign(changeset: FormFieldData.changeset(params))
    |> noreply()
  end

  def handle_event("save_note", %{"form_field_data" => params}, socket) do
    changeset = FormFieldData.changeset(params)

    case FormFieldData.investigation_note_attrs(changeset) do
      {:ok, note_attrs} ->
        socket.assigns.on_add.(note_attrs)
        socket |> assign(changeset: empty_note(socket.assigns)) |> noreply()

      {:error, error_changeset} ->
        socket |> assign(changeset: error_changeset) |> noreply()
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
    |> textarea.()
    |> Form.safe()
  end
end
