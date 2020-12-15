defmodule Epicenter.Cases.InvestigationNote do
  use Ecto.Schema
  import Ecto.Changeset

  @required_attrs ~w{author_id text}a
  @optional_attrs ~w{case_investigation_id deleted_at contact_investigation_id tid}a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @derive {Jason.Encoder, only: [:id] ++ @required_attrs ++ @optional_attrs}

  schema "investigation_notes" do
    field :deleted_at, :utc_datetime
    field :seq, :integer, read_after_writes: true
    field :text, :string
    field :tid, :string

    belongs_to :author, Epicenter.Accounts.User
    belongs_to :case_investigation, Epicenter.Cases.CaseInvestigation
    belongs_to :contact_investigation, Epicenter.Cases.ContactInvestigation

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(investigation_note, attrs) do
    investigation_note
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
  end
end
