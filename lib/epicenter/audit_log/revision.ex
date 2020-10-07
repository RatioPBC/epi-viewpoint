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

  def update_demographics_action(), do: "update-demographics"
  def update_assignment_bulk_action(), do: "update-assignment-bulk"
  def update_assignment_action(), do: "update-assignment"
  def update_profile_action(), do: "update-profile"
  def import_person_action(), do: "import-person"
  def releases_action(), do: "releases"

  def edit_profile_demographics_event(), do: "edit-profile-demographics"
  def people_selected_assignee_event(), do: "people-selected-assignee"
  def profile_selected_assignee_event(), do: "profile-selected-assignee"
  def edit_profile_saved_event(), do: "edit-profile-saved"
  def import_csv_event(), do: "import-csv"
  def releases_event(), do: "releases"

  defmodule Query do
    import Ecto.Query

    alias Epicenter.AuditLog
    alias Epicenter.AuditLog.Revision

    def with_changed_id(changed_id) do
      from revision in Revision,
        where: revision.changed_id == ^changed_id,
        order_by: revision.seq
    end

    def with_changed_type(changed_type) do
      changed_type_module_name = AuditLog.module_name(changed_type)

      from revision in Revision,
        where: revision.changed_type == ^changed_type_module_name,
        order_by: revision.seq
    end
  end
end
