defmodule EpicenterWeb.Forms.ResolveConflictsForm do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false

  embedded_schema do
    field :first_name, :string
  end

  def model_to_form_changeset(_merge_conflicts) do
    %__MODULE__{} |> cast(%{}, [:first_name])
  end

  #  def attrs_to_form_changeset(attrs) do
  #    attrs =
  #      attrs
  #      |> Euclid.Extra.Map.stringify_keys()
  #      |> Euclid.Extra.Map.transform(
  #           ~w{employment marital_status sex_at_birth},
  #           &Coerce.to_string_or_nil/1
  #         )
  #
  #    %ResolveConflictsForm{}
  #    |> cast(attrs, @required_attrs ++ @optional_attrs)
  #    |> validate_required(@required_attrs)
  #  end
end
