defmodule Epicenter.Cases do
  alias Epicenter.Cases.LabResult
  alias Epicenter.Cases.Person
  alias Epicenter.Repo

  #
  # lab results
  #
  def change_lab_result(%LabResult{} = lab_result, attrs), do: LabResult.changeset(lab_result, attrs)
  def create_lab_result!(attrs), do: %LabResult{} |> change_lab_result(attrs) |> Repo.insert!()
  def list_lab_results(), do: LabResult.Query.all() |> Repo.all()

  #
  # people
  #
  def change_person(%Person{} = person, attrs), do: Person.changeset(person, attrs)
  def create_person!(attrs), do: %Person{} |> change_person(attrs) |> Repo.insert!()
  def list_people(), do: Person.Query.all() |> Repo.all()
end
