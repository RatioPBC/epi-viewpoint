defmodule Epicenter.Cases.CaseInvestigationNote do
  use Ecto.Schema
  import Ecto.Changeset

  @required_attrs ~w{author_id case_investigation_id text}a
  @optional_attrs ~w{tid}a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @derive {Jason.Encoder, only: [:id] ++ @required_attrs ++ @optional_attrs}

  schema "case_investigation_notes" do
    field :seq, :integer
    field :text, :string
    field :tid, :string
    field :case_investigation_id, :binary_id

    belongs_to :author, Epicenter.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(case_investigation_note, attrs) do
    case_investigation_note
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
  end
end
