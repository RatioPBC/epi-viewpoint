defmodule Epicenter.Cases.Person.SearchTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Cases
  alias Epicenter.Cases.Person
  alias Epicenter.Test

  setup :persist_admin
  @admin Test.Fixtures.admin()

  defp create_person(tid, demographic_attrs \\ %{}) do
    Test.Fixtures.person_attrs(@admin, tid, %{}) |> Test.Fixtures.add_demographic_attrs(demographic_attrs) |> Cases.create_person!()
  end

  defp create_demographic(person, attrs) do
    attrs = %{source: "form"} |> Map.merge(attrs)
    {:ok, _result} = Test.Fixtures.demographic_attrs(@admin, person, nil, attrs) |> Cases.create_demographic()
    person
  end

  describe "find" do
    def search(term) do
      Person.Search.find(term, @admin) |> Enum.map(& &1.tid)
    end

    test "empty string returns empty results" do
      assert search("") == []
      assert search("   ") == []
    end

    test "finds the person associated with an external id" do
      create_person("person", %{external_id: "10004"})
      assert search("10004 10002 james") == ["person"]
    end

    test "finds the person associated with a viewpoint id" do
      person = create_person("person")
      assert search(person.id) == ["person"]
    end

    test "finds people whose coalesced first name or coalesced last name match any of the search terms" do
      create_person("first-name-match", %{first_name: "OldFirstName"})
      |> create_demographic(%{first_name: "NewFirstName"})

      create_person("last-name-match", %{last_name: "TestuserOldLastName"})
      |> create_demographic(%{last_name: "TestuserNewLastName"})

      assert search("NewFirstName TestuserNewLastName") == ["first-name-match", "last-name-match"]
      assert search("OldFirstName") == []
      assert search("TestuserOldLastName") == []
      assert search("NewFirstName TestuserOldLastName") == ["first-name-match"]
      assert search("OldFirstName TestuserNewLastName") == ["last-name-match"]
    end

    test "returning unique results" do
      create_person("alice", first_name: "alice", last_name: "testuser")
      assert search("alice testuser") == ["alice"]
    end

    test "searches are case-insensitive" do
      create_person("alice", first_name: "Alice", last_name: "TeStUsEr")
      assert search("alice") == ["alice"]
      assert search("Alice") == ["alice"]
      assert search("testuser") == ["alice"]
    end
  end
end
