defmodule Epicenter.Cases.Person.DuplicatesTest do
  use Epicenter.DataCase, async: true

  import Euclid.Extra.Enum, only: [tids: 1]

  alias Epicenter.Cases
  alias Epicenter.Cases.Person
  alias Epicenter.Test

  setup :persist_admin
  @admin Test.Fixtures.admin()

  describe "duplicates" do
    defp create_person(tid, attrs) do
      Test.Fixtures.person_attrs(@admin, tid, %{}) |> Test.Fixtures.add_demographic_attrs(attrs) |> Cases.create_person!()
    end

    defp add_phone(person, number) do
      Test.Fixtures.phone_attrs(@admin, person, person.tid, %{number: number}) |> Cases.create_phone!()
      person
    end

    #    defp add_address(person, number) do
    #      Test.Fixtures.address_attrs(@admin, person, person.tid, %{number: number}) |> Cases.create_phone!()
    #      person
    #    end

    defp create_demographic(person, attrs) do
      {:ok, _result} = Test.Fixtures.demographic_attrs(@admin, person, nil, attrs) |> Cases.create_demographic()
      person
    end

    test "returns empty list if there are no duplicates" do
      source = create_person("source", %{first_name: "Alice", last_name: "Testuser1", dob: ~D[2000-01-01]})
      create_person("different", %{first_name: "Different", last_name: "Testuser2", dob: ~D[1900-01-01]})
      Person.Duplicates.Query.all(source) |> Repo.all() |> assert_eq([])
    end

    # todo: also consider phone number and address
    # todo: also handle multiple demographics for a person
    test "returns people with the same last name at least one of the same: first name, date of birth" do
      first = "Alice"
      last = "Testuser1"
      dob = ~D[2004-01-01]
      phone = "111-111-1234"
      source = create_person("source", %{first_name: first, last_name: last, dob: dob}) |> add_phone(phone)

      # not duplicates
      create_person("different", %{first_name: "Different", last_name: "Testuser-different", dob: ~D[1900-01-01]})
      create_person("last-only", %{first_name: "Different", last_name: last, dob: ~D[1900-01-01]})
      create_person("first-only", %{first_name: first, last_name: "Testuser-different", dob: ~D[1900-01-01]})
      create_person("dob-only", %{first_name: "Different", last_name: "Testuser-different", dob: dob})
      create_person("last-used-to-match", %{first_name: first, last_name: last, dob: dob}) |> create_demographic(%{last_name: "Testuser-different"})

      create_person("first-used-to-match", %{first_name: first, last_name: last, dob: ~D[1900-01-01]})
      |> create_demographic(%{first_name: "Different"})

      create_person("dob-used-to-match", %{first_name: "Different", last_name: last, dob: dob}) |> create_demographic(%{dob: ~D[1900-01-01]})
      create_person("different-phone", %{first_name: "Different", last_name: last, dob: ~D[1900-01-01]}) |> add_phone("111-111-1999")
      #      create_person("different-address", %{first_name: "Different", last_name: last, dob: ~D[1900-01-01]}) |> add_address

      # duplicates
      create_person("last+first", %{first_name: first, last_name: last, dob: ~D[1900-01-01]})
      create_person("last+first-upcase", %{first_name: String.upcase(first), last_name: String.upcase(last), dob: ~D[1900-01-01]})
      create_person("last+dob", %{first_name: "Different", last_name: last, dob: dob})
      create_person("last+dob+first", %{first_name: first, last_name: last, dob: dob})
      create_person("last+phone", %{last_name: last}) |> add_phone(phone)

      create_person("latest-last+first", %{last_name: "Testuser-different", first_name: first})
      |> create_demographic(%{last_name: last, first_name: first})

      create_person("last+latest-first", %{last_name: last, first_name: "Different"}) |> create_demographic(%{last_name: last, first_name: first})

      create_person("last+latest-dob", %{last_name: last, dob: ~D[1900-01-01]})
      |> create_demographic(%{last_name: last, dob: dob})

      Person.Duplicates.Query.all(source)
      |> Repo.all()
      |> tids()
      |> assert_eq(~w{
        last+first
        last+first-upcase
        last+dob
        last+dob+first
        last+phone
        latest-last+first
        last+latest-first
        last+latest-dob
        },
        ignore_order: true
      )
    end
  end
end
