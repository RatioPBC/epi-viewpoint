defmodule EpicenterWeb.Forms.AddVisitForm do
  use Ecto.Schema

  import Ecto.Changeset

  alias Epicenter.DateParser
  alias EpicenterWeb.Forms.AddVisitForm

  @primary_key false
  @required_attrs ~w{}a
  @optional_attrs ~w{}a
  embedded_schema do
    field :occurred_on, :date
    field :relationship, :string
  end

  def changeset(_place, attrs) do
    %AddVisitForm{}
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
  end

  def visit_attrs(case_investigation, place, %{"add_visit_form" => add_visit_form_params}) do
    %{"occurred_on" => occurred_on, "relationship" => relationship} = add_visit_form_params
    occurred_on = DateParser.parse_mm_dd_yyyy!(occurred_on)

    %{
      case_investigation_id: case_investigation.id,
      place_id: place.id,
      occurred_on: occurred_on,
      relationship: relationship
    }
  end
end
