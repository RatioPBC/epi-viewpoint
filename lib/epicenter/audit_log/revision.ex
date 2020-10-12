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
  def upsert_person_action(), do: "upsert-person"
  def upsert_lab_result_action(), do: "upsert-lab-result"
  def upsert_phone_number_action(), do: "upsert-phone-number"
  def upsert_address_action(), do: "upsert-address"
  def import_csv_action(), do: "import-csv"
  def releases_action(), do: "releases"
  def register_user_action(), do: "register-user"
  def update_user_email_action(), do: "update-user-email"
  def update_user_email_request_action(), do: "update-user-email-request"
  def create_user_action(), do: "create-user"
  def disable_user_action(), do: "disable-user"
  def update_user_password_action(), do: "update-user-password"
  def reset_password_action(), do: "reset-password"
  def update_user_mfa_action(), do: "update-user-mfa"
  def login_user_action(), do: "login-user"

  def edit_profile_demographics_event(), do: "edit-profile-demographics"
  def people_selected_assignee_event(), do: "people-selected-assignee"
  def profile_selected_assignee_event(), do: "profile-selected-assignee"
  def edit_profile_saved_event(), do: "edit-profile-saved"
  def import_csv_event(), do: "import-csv"
  def releases_event(), do: "releases"
  def register_user_event(), do: "register-user"
  def reset_password_submit_event(), do: "reset-password-submit"
  def update_user_email_event(), do: "update-user-email"
  def update_user_email_request_event(), do: "update-user-email-request"
  def update_user_password_event(), do: "update-user-password"
  def update_user_mfa_event(), do: "update-user-mfa"
  def login_user_event(), do: "login-user"

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
