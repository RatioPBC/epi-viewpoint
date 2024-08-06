defmodule EpicenterWeb.Forms.AddVisitForm do
  use Ecto.Schema

  import Ecto.Changeset

  alias Epicenter.DateParser
  alias Epicenter.Validation
  alias EpicenterWeb.Forms.AddVisitForm

  @primary_key false
  @required_attrs ~w{occurred_on}a
  @optional_attrs ~w{relationship}a
  embedded_schema do
    field :occurred_on, :string
    field :relationship, :string
  end

  def changeset(_visit, attrs) do
    %AddVisitForm{}
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> Validation.validate_date(:occurred_on)
    |> validate_required(@required_attrs)
  end

  # if the visit is invalid, returns form_changeset, but marked to display validation messages
  # otherwise, returns attrs for creating a visit changeset
  def visit_attrs(%Ecto.Changeset{} = form_changeset) do
    with {:ok, visit_data} <- apply_action(form_changeset, :create) do
      {:ok,
       %{
         relationship: Map.get(visit_data, :relationship),
         occurred_on: Map.get(visit_data, :occurred_on) |> DateParser.parse_mm_dd_yyyy!()
       }}
    else
      other -> other
    end
  end
end
