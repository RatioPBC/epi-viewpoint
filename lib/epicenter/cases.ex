defmodule Epicenter.Cases do
  alias Epicenter.Accounts
  alias Epicenter.Accounts.User
  alias Epicenter.AuditLog
  alias Epicenter.Cases.Address
  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.ContactInvestigations.ContactInvestigation
  alias Epicenter.Cases.InvestigationNote
  alias Epicenter.Cases.Demographic
  alias Epicenter.Cases.Email
  alias Epicenter.Cases.Import
  alias Epicenter.Cases.ImportedFile
  alias Epicenter.Cases.LabResult
  alias Epicenter.Cases.Person
  alias Epicenter.Cases.Phone
  alias Epicenter.Repo

  import Ecto.Query, only: [distinct: 3, first: 1]

  @clock Application.get_env(:epicenter, :clock)

  #
  # lab results
  #
  def change_lab_result(%LabResult{} = lab_result, attrs), do: LabResult.changeset(lab_result, attrs)
  def count_lab_results(), do: LabResult |> Repo.aggregate(:count)
  def create_lab_result!({attrs, audit_meta}), do: %LabResult{} |> change_lab_result(attrs) |> AuditLog.insert!(audit_meta)
  def import_lab_results(lab_result_csv_string, originator), do: Import.import_csv(lab_result_csv_string, originator)
  def list_lab_results(), do: LabResult.Query.all() |> Repo.all()
  def preload_initiating_lab_result(case_investigations_or_nil), do: case_investigations_or_nil |> Repo.preload(:initiating_lab_result)
  def preload_lab_results(person_or_people_or_nil), do: person_or_people_or_nil |> Repo.preload(lab_results: LabResult.Query.display_order())

  def upsert_lab_result!({attrs, audit_meta}),
    do: %LabResult{} |> change_lab_result(attrs) |> AuditLog.insert!(audit_meta, LabResult.Query.opts_for_upsert())

  #
  # case investigations
  #
  def change_case_investigation(%CaseInvestigation{} = case_investigation, attrs), do: CaseInvestigation.changeset(case_investigation, attrs)

  def complete_case_investigation_interview(case_investigation, author_id, %{interview_completed_at: interview_completed_at} = params)
      when not is_nil(interview_completed_at) do
    update_case_investigation(
      case_investigation,
      {params,
       %AuditLog.Meta{
         author_id: author_id,
         reason_action: AuditLog.Revision.update_case_investigation_action(),
         reason_event: AuditLog.Revision.complete_case_investigation_interview_event()
       }}
    )
  end

  def create_case_investigation!({attrs, audit_meta}), do: %CaseInvestigation{} |> change_case_investigation(attrs) |> AuditLog.insert!(audit_meta)

  def get_case_investigation(id, user), do: AuditLog.get(CaseInvestigation, id, user)

  def preload_contact_investigations(has_many_contacts_or_nil, user) do
    has_many_contacts_or_nil
    |> Repo.preload(
      contact_investigations:
        {ContactInvestigation.Query.display_order(),
         [
           exposed_person: [phones: Ecto.Query.from(p in Phone, order_by: p.seq), demographics: Ecto.Query.from(d in Demographic, order_by: d.seq)]
         ]}
    )
    |> log_contact_investigations(user)
  end

  defp log_contact_investigations(has_many_contacts_or_nil, _user) when is_nil(has_many_contacts_or_nil), do: has_many_contacts_or_nil

  defp log_contact_investigations(has_many_contacts_or_nil, user) when is_list(has_many_contacts_or_nil),
    do: has_many_contacts_or_nil |> Enum.map(&log_contact_investigations(&1, user))

  defp log_contact_investigations(has_many_contacts_or_nil, user) do
    has_many_contacts_or_nil.contact_investigations |> AuditLog.view(user)
    has_many_contacts_or_nil
  end

  def preload_person(case_investigations_or_nil), do: case_investigations_or_nil |> Repo.preload(:person)

  def preload_case_investigations(person_or_people_or_nil),
    do: person_or_people_or_nil |> Repo.preload(case_investigations: CaseInvestigation.Query.display_order())

  def update_case_investigation(%CaseInvestigation{} = case_investigation, {attrs, audit_meta}),
    do: case_investigation |> change_case_investigation(attrs) |> AuditLog.update(audit_meta)

  #
  # investigation notes
  #
  def change_investigation_note(%InvestigationNote{} = investigation_note, attrs),
    do: InvestigationNote.changeset(investigation_note, attrs)

  def create_investigation_note({attrs, audit_meta}),
    do: %InvestigationNote{} |> change_investigation_note(attrs) |> AuditLog.insert(audit_meta)

  def create_investigation_note!({attrs, audit_meta}),
    do: %InvestigationNote{} |> change_investigation_note(attrs) |> AuditLog.insert!(audit_meta)

  def delete_investigation_note(investigation_note, audit_meta),
    do: InvestigationNote.changeset(investigation_note, %{deleted_at: @clock.utc_now()}) |> AuditLog.update(audit_meta)

  def preload_investigation_notes(case_investigations_or_nil), do: case_investigations_or_nil |> Repo.preload(:notes)

  def preload_author(notes_or_nil), do: notes_or_nil |> Repo.preload(:author)

  #
  # people
  #

  def archive_person(person_id, current_user, audit_meta),
    do: person_id |> get_person(current_user) |> Person.changeset_for_archive(current_user) |> AuditLog.update(audit_meta)

  def unarchive_person(person_id, %User{} = current_user, audit_meta),
    do: person_id |> get_person(current_user) |> Person.changeset_for_unarchive() |> AuditLog.update(audit_meta)

  def assign_user_to_people(user_id: nil, people_ids: people_ids, audit_meta: audit_meta, current_user: current_user),
    do: assign_user_to_people(user: nil, people_ids: people_ids, audit_meta: audit_meta, current_user: current_user)

  def assign_user_to_people(user_id: user_id, people_ids: people_ids, audit_meta: audit_meta, current_user: current_user),
    do: assign_user_to_people(user: Accounts.get_user(user_id), people_ids: people_ids, audit_meta: audit_meta, current_user: current_user)

  def assign_user_to_people(user: user, people_ids: people_ids, audit_meta: audit_meta, current_user: current_user) do
    all_updated =
      people_ids
      |> get_people(current_user)
      |> preload_demographics()
      |> Enum.map(fn person ->
        {:ok, updated} =
          person
          |> Person.assignment_changeset(user)
          |> AuditLog.update(audit_meta)

        %{updated | assigned_to: user}
      end)

    {:ok, all_updated}
  end

  def change_person(%Person{} = person, attrs), do: Person.changeset(person, attrs)
  def count_duplicate_people(person), do: person |> Person.Duplicates.Query.all() |> Repo.aggregate(:count)
  def count_people(), do: Person |> Repo.aggregate(:count)
  def create_person!({attrs, audit_meta}), do: %Person{} |> change_person(attrs) |> AuditLog.insert!(audit_meta)
  def create_person({attrs, audit_meta}), do: %Person{} |> change_person(attrs) |> AuditLog.insert(audit_meta)

  def find_matching_person(%{"dob" => dob, "first_name" => first_name, "last_name" => last_name})
      when not is_nil(dob) and not is_nil(first_name) and not is_nil(last_name) do
    Person
    |> Person.Query.with_demographic_field(:dob, dob)
    |> Person.Query.with_demographic_field(:first_name, first_name)
    |> Person.Query.with_demographic_field(:last_name, last_name)
    |> distinct([p], p.id)
    |> first()
    |> Repo.one()
  end

  def find_matching_person(_), do: nil
  def find_person_id_by_search_term(term), do: Person.Query.with_search_term(term) |> Repo.one()

  def get_people(ids, user), do: Person.Query.get_people(ids) |> AuditLog.all(user)
  def get_person(id, user), do: AuditLog.get(Person, id, user)

  def list_duplicate_people(%Person{} = person, user), do: person |> Person.Duplicates.Query.all() |> AuditLog.all(user)

  def list_people(filter, user: %User{} = user, reject_archived_people: reject_archived_people),
    do: Person.Query.filter_with_case_investigation(filter) |> Person.Query.reject_archived_people(reject_archived_people) |> AuditLog.all(user)

  def list_people(filter, assigned_to_id: user_id, user: %User{} = user, reject_archived_people: reject_archived_people),
    do:
      Person.Query.filter_with_case_investigation(filter)
      |> Person.Query.assigned_to_id(user_id)
      |> Person.Query.reject_archived_people(reject_archived_people)
      |> AuditLog.all(user)

  def preload_assigned_to(person_or_people_or_nil), do: person_or_people_or_nil |> Repo.preload([:assigned_to])
  def preload_archived_by(person_or_people_or_nil), do: person_or_people_or_nil |> Repo.preload([:archived_by])
  def update_person(%Person{} = person, {attrs, audit_meta}), do: person |> change_person(attrs) |> AuditLog.update(audit_meta)

  #
  # address
  #
  def change_address(%Address{} = address, attrs), do: Address.changeset(address, attrs)
  def count_addresses(), do: Address |> Repo.aggregate(:count)
  def create_address!({attrs, audit_meta}), do: %Address{} |> change_address(attrs) |> AuditLog.insert!(audit_meta)
  def preload_addresses(person_or_people_or_nil), do: person_or_people_or_nil |> Repo.preload(addresses: Address.Query.display_order())

  def upsert_address!({%{person_id: _} = attrs, audit_meta}),
    do: %Address{} |> change_address(attrs) |> AuditLog.insert!(audit_meta, Address.Query.opts_for_upsert())

  #
  # phone
  #
  def change_phone(%Phone{} = phone, attrs), do: Phone.changeset(phone, attrs)
  def count_phones(), do: Phone |> Repo.aggregate(:count)
  def create_phone!({attrs, audit_meta}), do: %Phone{} |> change_phone(attrs) |> AuditLog.insert!(audit_meta)
  def get_phone(id), do: Phone |> Repo.get(id)
  def list_phones(), do: Phone.Query.all() |> Repo.all()
  def preload_phones(person_or_people_or_nil), do: person_or_people_or_nil |> Repo.preload(phones: Phone.Query.display_order())

  def upsert_phone!({%{person_id: _} = attrs, audit_meta}),
    do: %Phone{} |> change_phone(attrs) |> AuditLog.insert!(audit_meta, Phone.Query.opts_for_upsert())

  #
  # email
  #
  def change_email(%Email{} = email, attrs), do: Email.changeset(email, attrs)
  def create_email!({email_attrs, audit_meta}), do: %Email{} |> change_email(email_attrs) |> AuditLog.insert!(audit_meta)
  def preload_emails(person_or_people_or_nil), do: person_or_people_or_nil |> Repo.preload(emails: Email.Query.display_order())

  #
  # imported files
  #
  def create_imported_file({attrs, audit_meta}), do: %ImportedFile{} |> ImportedFile.changeset(attrs) |> AuditLog.insert!(audit_meta)

  #
  # demographics
  #
  def change_demographic(demographic, attrs), do: Demographic.changeset(demographic, attrs)
  def create_demographic({attrs, audit_meta}), do: %Demographic{} |> change_demographic(attrs) |> AuditLog.insert(audit_meta)
  def get_demographic(%Person{} = person, source: :form), do: Demographic.Query.latest_form_demographic(person) |> Repo.one()
  def preload_demographics(person_or_people_or_nil), do: person_or_people_or_nil |> Repo.preload(demographics: Demographic.Query.display_order())
  def update_demographic(%Demographic{} = demo, {attrs, audit_meta}), do: demo |> change_demographic(attrs) |> AuditLog.update(audit_meta)
end
