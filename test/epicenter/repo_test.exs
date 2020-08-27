defmodule Epicenter.RepoTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Cases
  alias Epicenter.Repo
  alias Epicenter.Test

  describe "Versioned" do
    test "insert creates a version" do
      %Cases.Person{}
      |> Cases.Person.changeset(Test.Fixtures.person_attrs("alice", "01-01-2000"))
      |> Repo.Versioned.insert()
      |> changed_tids()
      |> assert_eq(~w{alice})
    end

    test "insert! creates a version" do
      %Cases.Person{}
      |> Cases.Person.changeset(Test.Fixtures.person_attrs("alice", "01-01-2000"))
      |> Repo.Versioned.insert!()
      |> changed_tids()
      |> assert_eq(~w{alice})
    end

    test "update creates a version" do
      person = Test.Fixtures.person_attrs("version-1", "01-01-2000") |> Cases.create_person!()

      person
      |> Cases.Person.changeset(%{tid: "version-2"})
      |> Repo.Versioned.update()
      |> changed_tids()
      |> assert_eq(~w{version-2 version-1})
    end

    test "update! creates a version" do
      person = Test.Fixtures.person_attrs("version-1", "01-01-2000") |> Cases.create_person!()

      person
      |> Cases.Person.changeset(%{tid: "version-2"})
      |> Repo.Versioned.update!()
      |> changed_tids()
      |> assert_eq(~w{version-2 version-1})
    end

    test "does not version empty changes" do
      person = Test.Fixtures.person_attrs("alice", "01-01-2000") |> Cases.create_person!()

      person
      |> changed_tids()
      |> assert_eq(~w{alice})

      person
      |> Cases.change_person(%{tid: person.tid})
      |> Repo.Versioned.update!()
      |> changed_tids()
      |> assert_eq(~w{alice})
    end

    test "all_versions returns all versions sorted by id desc" do
      person = Test.Fixtures.person_attrs("version-1", "01-01-2000") |> Cases.create_person!()
      person |> Cases.Person.changeset(%{tid: "version-2"}) |> Repo.Versioned.update!()

      person |> changed_tids() |> assert_eq(~w{version-2 version-1})
    end

    test "last_version returns most recent version" do
      person = Test.Fixtures.person_attrs("version-1", "01-01-2000") |> Cases.create_person!()
      assert Repo.Versioned.last_version(person) |> Map.get(:item_changes) |> Map.get("tid") == "version-1"

      person |> Cases.Person.changeset(%{tid: "version-2"}) |> Repo.Versioned.update!()
      assert Repo.Versioned.last_version(person) |> Map.get(:item_changes) |> Map.get("tid") == "version-2"
    end
  end

  defp changed_tids({:ok, schema}),
    do: schema |> Repo.Versioned.all_versions() |> Euclid.Extra.Enum.pluck(:item_changes) |> Enum.map(& &1["tid"])

  defp changed_tids(schema),
    do: schema |> Repo.Versioned.all_versions() |> Euclid.Extra.Enum.pluck(:item_changes) |> Enum.map(& &1["tid"])
end
