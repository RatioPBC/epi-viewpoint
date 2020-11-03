defmodule Epicenter.Cases do
  alias Epicenter.Accounts
  alias Epicenter.AuditLog
  alias Epicenter.Cases.Address
  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Cases.Demographic
  alias Epicenter.Cases.Email
  alias Epicenter.Cases.Import
  alias Epicenter.Cases.ImportedFile
  alias Epicenter.Cases.LabResult
  alias Epicenter.Cases.Person
  alias Epicenter.Cases.Phone
  alias Epicenter.Repo

  #
  # lab results
  #
  def change_lab_result(%LabResult{} = lab_result, attrs), do: LabResult.changeset(lab_result, attrs)
  def count_lab_results(), do: LabResult |> Repo.aggregate(:count)
  def create_lab_result!({attrs, audit_meta}), do: %LabResult{} |> change_lab_result(attrs) |> AuditLog.insert!(audit_meta)
  def import_lab_results(lab_result_csv_string, originator), do: Import.import_csv(lab_result_csv_string, originator)
  def list_lab_results(), do: LabResult.Query.all() |> Repo.all()
  def preload_lab_results(person_or_people_or_nil), do: person_or_people_or_nil |> Repo.preload(lab_results: LabResult.Query.display_order())

  def upsert_lab_result!({attrs, audit_meta}),
    do: %LabResult{} |> change_lab_result(attrs) |> AuditLog.insert!(audit_meta, LabResult.Query.opts_for_upsert())

  #
  # case investigations
  #
  def get_case_investigation(id), do: CaseInvestigation |> Repo.get(id)
  def change_case_investigation(%CaseInvestigation{} = case_investigation, attrs), do: CaseInvestigation.changeset(case_investigation, attrs)
  def create_case_investigation!({attrs, audit_meta}), do: %CaseInvestigation{} |> change_case_investigation(attrs) |> AuditLog.insert!(audit_meta)

  def update_case_investigation(%CaseInvestigation{} = case_investigation, {attrs, audit_meta}),
    do: case_investigation |> change_case_investigation(attrs) |> AuditLog.update(audit_meta)

  def preload_case_investigations(person_or_people_or_nil),
    do: person_or_people_or_nil |> Repo.preload(case_investigations: CaseInvestigation.Query.display_order())

  def preload_initiated_by(case_investigations_or_nil),
    do: case_investigations_or_nil |> Repo.preload(:initiated_by)

  def preload_person(case_investigations_or_nil),
    do: case_investigations_or_nil |> Repo.preload(:person)

  #
  # people
  #
  def assign_user_to_people(user_id: nil, people_ids: people_ids, audit_meta: audit_meta),
    do: assign_user_to_people(user: nil, people_ids: people_ids, audit_meta: audit_meta)

  def assign_user_to_people(user_id: user_id, people_ids: people_ids, audit_meta: audit_meta),
    do: assign_user_to_people(user: Accounts.get_user(user_id), people_ids: people_ids, audit_meta: audit_meta)

  def assign_user_to_people(user: user, people_ids: people_ids, audit_meta: audit_meta) do
    all_updated =
      people_ids
      |> get_people()
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

  def broadcast_people(people), do: Phoenix.PubSub.broadcast(Epicenter.PubSub, "people", {:people, people})
  def change_person(%Person{} = person, attrs), do: Person.changeset(person, attrs)
  def count_people(), do: Person |> Repo.aggregate(:count)
  def create_person!({attrs, audit_meta}), do: %Person{} |> change_person(attrs) |> AuditLog.insert!(audit_meta)
  def create_person({attrs, audit_meta}), do: %Person{} |> change_person(attrs) |> AuditLog.insert(audit_meta)

  def find_matching_person(%{"dob" => dob, "first_name" => first_name, "last_name" => last_name}) do
    with %Demographic{} = demographic <- Demographic.Query.matching(dob: dob, first_name: first_name, last_name: last_name) |> Repo.one() do
      Repo.preload(demographic, [:person]).person
    end
  end

  def get_people(ids), do: Person.Query.get_people(ids) |> Repo.all()
  def get_person(id), do: Person |> Repo.get(id)
  def list_people(:all), do: Person.Query.all() |> Repo.all()
  def list_people(:call_list), do: Person.Query.call_list() |> Repo.all()
  def list_people(:with_lab_results), do: Person.Query.with_lab_results() |> Repo.all()
  def list_people(), do: list_people(:all)
  def preload_assigned_to(person_or_people_or_nil), do: person_or_people_or_nil |> Repo.preload([:assigned_to])
  def preload_demographics(person_or_people_or_nil), do: person_or_people_or_nil |> Repo.preload(demographics: Demographic.Query.display_order())
  def subscribe_to_people(), do: Phoenix.PubSub.subscribe(Epicenter.PubSub, "people")
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

  def create_demographic({attrs, audit_meta}) do
    %Demographic{} |> change_demographic(attrs) |> AuditLog.insert(audit_meta)
  end
end
