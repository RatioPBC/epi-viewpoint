defmodule EpicenterWeb.Forms.CaseInvestigationNoteForm do
  alias EpicenterWeb.Form

  def add_note_form_builder(form, _case_investigation) do
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
end
