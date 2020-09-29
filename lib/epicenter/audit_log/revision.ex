defmodule Epicenter.AuditLog.Revision do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "revisions" do
    field :after_change, :map
    field :author_id, :binary_id
    field :before_change, :map
    field :change, :map
    field :changed_id, :string
    field :changed_type, :string
    field :reason_action, :string
    field :reason_event, :string
    field :seq, :integer
    field :tid, :string

    timestamps(updated_at: false)
  end

  @required_attrs ~w{after_change author_id before_change change changed_id changed_type reason_action reason_event}a
  @optional_attrs ~w{tid}a

  def changeset(revision, attrs) do
    revision
    |> cast(Enum.into(attrs, %{}), @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
  end

  def edit_profile_demographics_event(), do: "edit-profile-demographics"

  def update_demographics_action(), do: "update-demographics"

  defmodule Query do
    import Ecto.Query

    alias Epicenter.AuditLog
    alias Epicenter.AuditLog.Revision

    def with_changed_type(changed_type) do
      changed_type_module_name = AuditLog.module_name(changed_type)

      from revision in Revision,
        where: revision.changed_type == ^changed_type_module_name,
        order_by: revision.seq
    end
  end
end
