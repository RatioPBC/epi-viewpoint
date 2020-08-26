defmodule Epicenter.Cases do
  alias Epicenter.Cases.Case
  alias Epicenter.Cases.Import
  alias Epicenter.Cases.LabResult
  alias Epicenter.Cases.Person
  alias Epicenter.Repo

  #
  # cases
  #
  def list_cases(), do: list_people() |> Case.new()

  #
  # lab results
  #
  def change_lab_result(%LabResult{} = lab_result, attrs), do: LabResult.changeset(lab_result, attrs)
  def count_lab_results(), do: LabResult |> Repo.aggregate(:count)
  def create_lab_result!(attrs), do: %LabResult{} |> change_lab_result(attrs) |> Repo.insert!()
  def import_lab_results(lab_result_csv_string), do: Import.from_csv(lab_result_csv_string)
  def list_lab_results(), do: LabResult.Query.all() |> Repo.all()

  #
  # people
  #
  def change_person(%Person{} = person, attrs), do: Person.changeset(person, attrs)
  def count_people(), do: Person |> Repo.aggregate(:count)
  def create_person(attrs), do: %Person{} |> change_person(attrs) |> Repo.insert_with_version()
  def create_person!(attrs), do: %Person{} |> change_person(attrs) |> Repo.insert_with_version!()
  def get_person(id), do: Person |> Repo.get(id)
  def list_people(), do: list_people(:all)
  def list_people(:all), do: Person.Query.all() |> Repo.all()
  def list_people(:call_list), do: Person.Query.call_list() |> Repo.all()
  def preload_lab_results(person_or_people_or_nil), do: person_or_people_or_nil |> Repo.preload([:lab_results])
  def update_person(%Person{} = person, attrs), do: person |> change_person(attrs) |> Repo.update_with_version()
  def upsert_person!(attrs), do: %Person{} |> change_person(attrs) |> Repo.insert!(Person.Query.opts_for_upsert())

  #
  # pubsub
  #
  def broadcast(message), do: Phoenix.PubSub.broadcast(Epicenter.PubSub, "cases", message)
  def subscribe(), do: Phoenix.PubSub.subscribe(Epicenter.PubSub, "cases")
end
