defmodule EpicenterWeb.Forms.ResolveConflictsForm do
  use Ecto.Schema

  import Ecto.Changeset

  alias Epicenter.Cases.Merge
  alias Epicenter.Validation
  alias EpicenterWeb.Forms.ResolveConflictsForm

  @primary_key false
  @required_attrs ~w{}a
  @optional_attrs ~w{first_name dob preferred_language}a
  embedded_schema do
    field(:first_name, :string)
    field(:dob, :string)
    field(:preferred_language, :string)
  end

  def changeset(merge_conflicts, attrs) do
    %ResolveConflictsForm{}
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> Validation.validate_date(:dob)
    |> validate_required(Merge.fields_with_conflicts(merge_conflicts))
  end
end
