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
      %Cases.Phone{} = Test.Fixtures.phone_attrs(@admin, person, person.tid, %{number: number}) |> Cases.create_phone!()
      person
    end

    defp add_address(person, address \\ :source) do
      attrs = %{
        source: %{street: "1000 Test St", city: "City1", state: "CA", postal_code: "00001"},
        different_street: %{street: "1001 Test St", city: "City1", state: "CA", postal_code: "00001"},
        different_city: %{street: "1000 Test St", city: "City2", state: "CA", postal_code: "00001"},
        different_state: %{street: "1000 Test St", city: "City1", state: "NC", postal_code: "00001"},
        different_postal_code: %{street: "1000 Test St", city: "City1", state: "CA", postal_code: "00002"},
        different_everything: %{street: "1001 Test St", city: "City2", state: "NC", postal_code: "00002"}
      }

      %Cases.Address{} = Test.Fixtures.address_attrs(@admin, person, "address-" <> person.tid, 0, attrs[address]) |> Cases.create_address!()
      person
    end

    defp create_demographic(person, attrs) do
      {:ok, _result} = Test.Fixtures.demographic_attrs(@admin, person, nil, attrs) |> Cases.create_demographic()
      person
    end

    test "returns empty list if there are no duplicates" do
      source = create_person("source", %{first_name: "Alice", last_name: "Testuser1", dob: ~D[2000-01-01]})
      create_person("different", %{first_name: "Different", last_name: "Testuser2", dob: ~D[1900-01-01]})
      Person.Duplicates.Query.all(source) |> Repo.all() |> assert_eq([])
    end

    test "returns people with the same last name at least one of the same: first name, date of birth" do
      first = "Alice"
      last = "Testuser1"
      dob = ~D[2004-01-01]
      phone = "111-111-1234"
      source = create_person("source", %{first_name: first, last_name: last, dob: dob}) |> add_phone(phone) |> add_address()

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
      create_person("different-address", %{first_name: "Different", last_name: last, dob: ~D[1900-01-01]}) |> add_address(:different_everything)
      create_person("different-street", %{first_name: "Different", last_name: last, dob: ~D[1900-01-01]}) |> add_address(:different_street)
      create_person("different-city", %{first_name: "Different", last_name: last, dob: ~D[1900-01-01]}) |> add_address(:different_city)
      create_person("different-state", %{first_name: "Different", last_name: last, dob: ~D[1900-01-01]}) |> add_address(:different_state)
      create_person("different-postal_code", %{first_name: "Different", last_name: last, dob: ~D[1900-01-01]}) |> add_address(:different_postal_code)

      create_person("last+first+but-archived", %{first_name: first, last_name: last, dob: ~D[1900-01-01]})
      |> Map.get(:id)
      |> Cases.archive_person(@admin, Test.Fixtures.admin_audit_meta())

      # duplicates
      create_person("last+first", %{first_name: first, last_name: last, dob: ~D[1900-01-01]})
      create_person("last+first-upcase", %{first_name: String.upcase(first), last_name: String.upcase(last), dob: ~D[1900-01-01]})
      create_person("last+dob", %{first_name: "Different", last_name: last, dob: dob})
      create_person("last+dob+first", %{first_name: first, last_name: last, dob: dob})
      create_person("last+phone", %{last_name: last}) |> add_phone(phone)
      create_person("last+address", %{last_name: last}) |> add_address(:source)

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
        last+address
        },
        ignore_order: true
      )
    end
  end
end
