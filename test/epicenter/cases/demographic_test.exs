defmodule Epicenter.Cases.DemographicTest do
  use Epicenter.DataCase, async: true

  import Euclid.Extra.Enum, only: [tids: 1]

  alias Epicenter.Cases
  alias Epicenter.Cases.Demographic
  alias Epicenter.Test

  defp new_changeset(attr_updates) do
    Demographic.changeset(%Demographic{}, attr_updates)
  end

  test "validates personal health information on dob", do: assert_invalid(new_changeset(%{dob: "01-10-2000"}))
  test "validates personal health information on last_name", do: assert_invalid(new_changeset(%{last_name: "Aliceblat"}))

  describe "Query.display_order" do
    test "sorts by insertion order" do
      author = Test.Fixtures.admin()
      {:ok, person} = Test.Fixtures.person_attrs(author, "person") |> Cases.create_person()
      {:ok, _} = Test.Fixtures.demographic_attrs(author, person, "first") |> Cases.find_or_create_demographic()
      {:ok, _} = Test.Fixtures.demographic_attrs(author, person, "second") |> Cases.find_or_create_demographic()
      {:ok, _} = Test.Fixtures.demographic_attrs(author, person, "third") |> Cases.find_or_create_demographic()

      Demographic.Query.display_order() |> Repo.all() |> tids() |> assert_eq([nil, "first", "second", "third"])
    end
  end
end
