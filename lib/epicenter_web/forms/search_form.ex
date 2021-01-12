defmodule EpicenterWeb.Forms.SearchForm do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false

  embedded_schema do
    field :term, :string
  end

  def changeset(%__MODULE__{} = search_form, attrs) do
    %__MODULE__{
      term: search_form.term
    }
    |> cast(attrs, [:term])
    |> validate_required([:term])
  end
end
