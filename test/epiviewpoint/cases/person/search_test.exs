defmodule EpiViewpoint.Cases.Person.SearchTest do
  use EpiViewpoint.DataCase, async: true

  import Euclid.Extra.Enum, only: [tids: 1]

  alias EpiViewpoint.Cases
  alias EpiViewpoint.Cases.Person
  alias EpiViewpoint.Test
  alias EpiViewpoint.Test.AuditLogAssertions

  setup :persist_admin
  @admin Test.Fixtures.admin()

  defp create_person(tid, demographic_attrs \\ %{}, person_attrs \\ %{}) do
    Test.Fixtures.person_attrs(@admin, tid, person_attrs) |> Test.Fixtures.add_demographic_attrs(demographic_attrs) |> Cases.create_person!()
  end

  defp create_demographic(person, attrs) do
    attrs = %{source: "form"} |> Map.merge(attrs)
    {:ok, _result} = Test.Fixtures.demographic_attrs(@admin, person, nil, attrs) |> Cases.create_demographic()
    person
  end

  describe "Cases.search_people context delegation" do
    def search_via_context(term) do
      Cases.search_people(term, @admin) |> tids()
    end

    test "finds people" do
      create_person("alice")
      assert search_via_context("alice") == ~w[alice]
    end

    test "viewpoint id results are audit logged" do
      person = create_person("person")

      AuditLogAssertions.expect_phi_view_logs(1)
      search_via_context(person.id)

      AuditLogAssertions.verify_phi_view_logged(@admin, [person])
    end

    test "non-viewpoint-id results are audit logged" do
      alice = create_person("alice", first_name: "alice", last_name: "testuser")

      AuditLogAssertions.expect_phi_view_logs(1)
      search_via_context("alice testuser")
      AuditLogAssertions.verify_phi_view_logged(@admin, [alice])
    end
  end

  describe "find" do
    def search(term) do
      Person.Search.find(term) |> tids()
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

      assert search("NewFirstName TestuserNewLastName") == ["last-name-match", "first-name-match"]
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

    test "ignore archived people" do
      archived = create_person("archived", %{first_name: "alice"}, %{archived_at: DateTime.utc_now(), archived_by: @admin})
      not_archived = create_person("not-archived", %{first_name: "alice"}, %{archived_at: nil, archived_by: nil})

      assert search("alice") == ~w[not-archived]
      assert search(not_archived.id) == ~w[not-archived]
      assert search(archived.id) == []
    end

    test "orders results by first name and last name" do
      create_person("billy", first_name: "Billy", last_name: "Testuser")
      create_person("alice", first_name: "Alice", last_name: "Testuser")

      assert search("testuser") == ["alice", "billy"]
    end
  end
end
