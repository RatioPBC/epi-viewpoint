defmodule EpicenterWeb.Forms.CaseInvestigationNoteForm do
  alias EpicenterWeb.Form

  def add_note_form_builder(form, _case_investigation) do
    Form.new(form)
    |> Form.line(&Form.hidden_field(&1, :case_investigation_id))
    |> Form.line(&Form.textarea_field(&1, :text, "Add note", span: 3))
    |> Form.line(&Form.save_button(&1))
    |> Form.safe()
  end

  defmodule FormFieldData do
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :author_id, :binary_id
      field :case_investigation_id, :binary_id
      field :text, :string
    end

    @required_attrs ~w{author_id case_investigation_id text}a

    def add_note_changeset(case_investigation) do
      %__MODULE__{}
      |> cast(%{case_investigation_id: case_investigation.id}, @required_attrs)
      |> validate_required(@required_attrs)
    end

    def attrs_to_form_changeset(attrs, author) do
      attrs = Map.put(attrs, "author_id", author.id)

      %__MODULE__{}
      |> cast(attrs, @required_attrs)
    end

    def case_investigation_note_attrs(%Ecto.Changeset{} = form_changeset) do
      with {:ok, form_field_data} <- apply_action(form_changeset, :create) do
        {:ok, %{case_investigation_id: form_field_data.case_investigation_id, text: form_field_data.text, author_id: form_field_data.author_id}}
      else
        other -> other
      end
    end
  end
end
