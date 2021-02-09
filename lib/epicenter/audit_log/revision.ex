defmodule Epicenter.AuditLog.Revision do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "revisions" do
    field :after_change, :map
    field :application_version_sha, :string
    field :author_id, :binary_id
    field :before_change, :map
    field :change, :map
    field :changed_id, :string
    field :changed_type, :string
    field :reason_action, :string
    field :reason_event, :string
    field :seq, :integer, read_after_writes: true
    field :tid, :string

    timestamps(updated_at: false)
  end

  @required_attrs ~w{after_change application_version_sha author_id before_change change changed_id changed_type reason_action reason_event}a
  @optional_attrs ~w{tid}a

  def changeset(revision, attrs) do
    revision
    |> cast(Enum.into(attrs, %{}), @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
  end

  # action = what was the code that made this change trying to accomplish?
  def archive_person_action(), do: "archive-person"
  def create_address_action(), do: "create-address"
  def create_case_investigation_note_action(), do: "create-case-investigation-note"
  def create_contact_action(), do: "create-contact"
  def create_contact_investigation_note_action(), do: "create-contact-investigation-note"
  def create_email_action(), do: "create-email"
  def create_phone_action(), do: "create-phone"
  def create_user_action(), do: "create-user"
  def delete_case_investigation_note_action(), do: "delete-case-investigation-note"
  def delete_contact_investigation_note_action(), do: "delete-contact-investigation-note"
  def demote_user_action(), do: "demote-user"
  def enable_user_action(), do: "enable-user"
  def import_csv_action(), do: "import-csv"
  def insert_case_investigation_action(), do: "insert-case-investigation"
  def insert_demographics_action(), do: "insert-demographics"
  def login_user_action(), do: "login-user"
  def merge_people_action(), do: "merge-people"
  def promote_user_action(), do: "promote-user"
  def register_user_action(), do: "register-user"
  def releases_action(), do: "releases"
  def remove_contact_investigation_action(), do: "remove-contact-investigation"
  def reset_password_action(), do: "reset-password"
  def unarchive_person_action(), do: "unarchive-person"
  def update_assignment_action(), do: "update-assignment"
  def update_assignment_bulk_action(), do: "update-assignment-bulk"
  def update_case_investigation_action(), do: "update-case-investigation"
  def update_contact_investigation_action(), do: "update-contact-investigation"
  def update_demographics_action(), do: "update-demographics"
  def update_disabled_action(), do: "disable-user"
  def update_profile_action(), do: "update-profile"
  def update_user_email_action(), do: "update-user-email"
  def update_user_email_request_action(), do: "update-user-email-request"
  def update_user_mfa_action(), do: "update-user-mfa"
  def update_user_password_action(), do: "update-user-password"
  def update_user_registration_action(), do: "update-user-registration"
  def upsert_address_action(), do: "upsert-address"
  def upsert_lab_result_action(), do: "upsert-lab-result"
  def upsert_person_action(), do: "upsert-person"
  def upsert_phone_number_action(), do: "upsert-phone-number"

  # event = what occurred that caused the code to make an action? (usually something the user did)
  def admin_create_user_event, do: "admin-create-user"
  def admin_update_user_event, do: "admin-update-user"
  def complete_case_investigation_interview_event(), do: "complete-case-investigation-interview"
  def complete_contact_investigation_interview_event(), do: "complete-contact-investigation-interview"
  def conclude_case_investigation_isolation_monitoring_event, do: "conclude-case-investigation-isolation-monitoring"
  def conclude_contact_investigation_quarantine_monitoring_event(), do: "conclude-contact-investigation-quarantine-monitoring"
  def contacts_archive_people_event(), do: "contacts-archive-people"
  def create_contact_event(), do: "create-contact"
  def discontinue_contact_investigation_event(), do: "discontinue-contact-investigation"
  def discontinue_pending_case_interview_event(), do: "discontinue-pending-case-interview"
  def edit_case_interview_clinical_details_event(), do: "edit-case-investigation-clinical-details"
  def edit_case_investigation_isolation_monitoring_event(), do: "edit-case-investigation-isolation-monitoring"
  def edit_case_investigation_isolation_order_event(), do: "edit-case-investigation-isolation-order"
  def edit_contact_investigation_clinical_details_event(), do: "edit-contact-investigation-clinical-details"
  def edit_contact_investigation_quarantine_monitoring_event(), do: "edit-contact-investigation-quarantine-monitoring"
  def edit_profile_demographics_event(), do: "edit-profile-demographics"
  def edit_profile_saved_event(), do: "edit-profile-saved"
  def import_csv_event(), do: "import-csv"
  def login_user_event(), do: "login-user"
  def merge_people_event(), do: "merge-people-event"
  def people_archive_people_event(), do: "people-archive-people"
  def people_selected_assignee_event(), do: "people-selected-assignee"
  def profile_archive_person_event(), do: "profile-archive-person"
  def profile_case_investigation_note_deletion_event(), do: "profile-case-investigation-note-deletion"
  def profile_case_investigation_note_submission_event(), do: "profile-case-investigation-note-submission"
  def profile_contact_investigation_note_deletion_event(), do: "profile-contact-investigation-note-deletion"
  def profile_contact_investigation_note_submission_event(), do: "profile-contact-investigation-note-submission"
  def profile_selected_assignee_event(), do: "profile-selected-assignee"
  def profile_unarchive_person_event(), do: "profile-unarchive-person"
  def register_user_event(), do: "register-user"
  def releases_event(), do: "releases"
  def remove_contact_event(), do: "remove-contact"
  def reset_password_submit_event(), do: "reset-password-submit"
  def save_merge_event(), do: "save-merge"
  def seed_event(), do: "seeds"
  def start_interview_event(), do: "start-interview"
  def update_contact_event(), do: "update-contact"
  def update_user_email_event(), do: "update-user-email"
  def update_user_email_request_event(), do: "update-user-email-request"
  def update_user_mfa_event(), do: "update-user-mfa"
  def update_user_password_event(), do: "update-user-password"

  defmodule Query do
    import Ecto.Query

    alias Epicenter.AuditingRepo
    alias Epicenter.AuditLog.Revision

    def with_changed_id(changed_id) do
      from revision in Revision,
        where: revision.changed_id == ^changed_id,
        order_by: revision.seq
    end

    def with_changed_type(changed_type) do
      changed_type_module_name = AuditingRepo.module_name(changed_type)

      from revision in Revision,
        where: revision.changed_type == ^changed_type_module_name,
        order_by: revision.seq
    end
  end
end
