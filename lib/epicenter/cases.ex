defmodule Epicenter.Cases do
  alias Epicenter.Accounts.User
  alias Epicenter.Cases.Address
  alias Epicenter.Cases.Email
  alias Epicenter.Cases.Import
  alias Epicenter.Cases.LabResult
  alias Epicenter.Cases.Person
  alias Epicenter.Cases.Phone
  alias Epicenter.Repo

  #
  # lab results
  #
  def change_lab_result(%LabResult{} = lab_result, attrs), do: LabResult.changeset(lab_result, attrs)
  def count_lab_results(), do: LabResult |> Repo.aggregate(:count)
  def create_lab_result!(attrs), do: %LabResult{} |> change_lab_result(attrs) |> Repo.insert!()
  def import_lab_results(lab_result_csv_string, originator), do: Import.import_csv(lab_result_csv_string, originator)
  def list_lab_results(), do: LabResult.Query.all() |> Repo.all()
  def preload_lab_results(person_or_people_or_nil), do: person_or_people_or_nil |> Repo.preload([:lab_results])

  #
  # people
  #
  def change_person(%Person{} = person, attrs), do: Person.changeset(person, attrs)
  def count_people(), do: Person |> Repo.aggregate(:count)
  def create_person(attrs), do: %Person{} |> change_person(attrs) |> Repo.Versioned.insert()
  def create_person!(attrs), do: %Person{} |> change_person(attrs) |> Repo.Versioned.insert!()
  def get_person(id), do: Person |> Repo.get(id)
  def list_people(), do: list_people(:all)
  def list_people(:all), do: Person.Query.all() |> Repo.all()
  def list_people(:with_lab_results), do: Person.Query.with_lab_results() |> Repo.all()
  def list_people(:call_list), do: Person.Query.call_list() |> Repo.all()
  def preload_assigned_to(person_or_people_or_nil), do: person_or_people_or_nil |> Repo.preload([:assigned_to])
  def update_assignment(%Person{} = person, %User{} = user), do: person |> Person.assignment_changeset(user) |> Repo.Versioned.update()
  def update_person(%Person{} = person, attrs), do: person |> change_person(attrs) |> Repo.Versioned.update()
  def upsert_person!(attrs), do: %Person{} |> change_person(attrs) |> Repo.Versioned.insert!(ecto_options: Person.Query.opts_for_upsert())

  #
  # address
  #
  def change_address(%Address{} = address, attrs), do: Address.changeset(address, attrs)
  def create_address!(attrs), do: %Address{} |> change_address(attrs) |> Repo.insert!()
  def preload_addresses(person_or_people_or_nil), do: person_or_people_or_nil |> Repo.preload(addresses: Address.Query.display_order())

  #
  # phone
  #
  def change_phone(%Phone{} = phone, attrs), do: Phone.changeset(phone, attrs)
  def count_phones(), do: Phone |> Repo.aggregate(:count)
  def create_phone(attrs), do: %Phone{} |> change_phone(attrs) |> Repo.insert()
  def create_phone!(attrs), do: %Phone{} |> change_phone(attrs) |> Repo.insert!()
  def preload_phones(person_or_people_or_nil), do: person_or_people_or_nil |> Repo.preload(phones: Phone.Query.display_order())

  #
  # email
  #
  def change_email(%Email{} = email, attrs), do: Email.changeset(email, attrs)
  def create_email!(email_attrs), do: %Email{} |> change_email(email_attrs) |> Repo.insert!()
  def preload_emails(person_or_people_or_nil), do: person_or_people_or_nil |> Repo.preload(emails: Email.Query.display_order())

  #
  # pubsub
  #
  def broadcast(message), do: Phoenix.PubSub.broadcast(Epicenter.PubSub, "cases", message)
  def subscribe(), do: Phoenix.PubSub.subscribe(Epicenter.PubSub, "cases")
end
