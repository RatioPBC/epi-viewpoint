defmodule Epicenter.RepoTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Repo
  alias Epicenter.Test

  describe "Versioned" do
    setup do
      user = Test.Fixtures.user_attrs("user") |> Accounts.create_user!()
      person_changeset = %Cases.Person{} |> Cases.Person.changeset(Test.Fixtures.person_attrs(user, "version-1", external_id: "10000"))
      [person_changeset: person_changeset, user: user]
    end

    test "insert creates a version", %{person_changeset: person_changeset, user: user} do
      person_changeset
      |> Repo.Versioned.insert()
      |> assert_versions([
        [
          change: %{
            "assigned_to_id" => nil,
            "dob" => "2000-01-01",
            "external_id" => "10000",
            "fingerprint" => "2000-01-01 version-1 testuser",
            "first_name" => "Version-1",
            "last_name" => "Testuser",
            "originator" => %{"id" => user.id},
            "preferred_language" => "English",
            "tid" => "version-1"
          },
          by: "user"
        ]
      ])
    end

    test "insert! creates a version", %{person_changeset: person_changeset, user: user} do
      person_changeset
      |> Repo.Versioned.insert!()
      |> assert_versions([
        [
          change: %{
            "assigned_to_id" => nil,
            "dob" => "2000-01-01",
            "external_id" => "10000",
            "fingerprint" => "2000-01-01 version-1 testuser",
            "first_name" => "Version-1",
            "last_name" => "Testuser",
            "originator" => %{"id" => user.id},
            "preferred_language" => "English",
            "tid" => "version-1"
          },
          by: "user"
        ]
      ])
    end

    test "update creates a version", %{person_changeset: person_changeset, user: user} do
      person = person_changeset |> Repo.Versioned.insert!()

      person
      |> Cases.Person.changeset(%{tid: "version-2"})
      |> Repo.Versioned.update()
      |> assert_versions([
        [change: %{"tid" => "version-2"}, by: "user"],
        [
          change: %{
            "assigned_to_id" => nil,
            "dob" => "2000-01-01",
            "external_id" => "10000",
            "fingerprint" => "2000-01-01 version-1 testuser",
            "first_name" => "Version-1",
            "last_name" => "Testuser",
            "originator" => %{"id" => user.id},
            "preferred_language" => "English",
            "tid" => "version-1"
          },
          by: "user"
        ]
      ])
    end

    test "update! creates a version", %{person_changeset: person_changeset, user: user} do
      person = person_changeset |> Repo.Versioned.insert!()

      person
      |> Cases.Person.changeset(%{tid: "version-2"})
      |> Repo.Versioned.update!()
      |> assert_versions([
        [change: %{"tid" => "version-2"}, by: "user"],
        [
          change: %{
            "assigned_to_id" => nil,
            "dob" => "2000-01-01",
            "external_id" => "10000",
            "fingerprint" => "2000-01-01 version-1 testuser",
            "first_name" => "Version-1",
            "last_name" => "Testuser",
            "originator" => %{"id" => user.id},
            "preferred_language" => "English",
            "tid" => "version-1"
          },
          by: "user"
        ]
      ])
    end

    test "does not version empty changes", %{person_changeset: person_changeset, user: user} do
      person = person_changeset |> Repo.Versioned.insert!()

      person
      |> assert_versions([
        [
          change: %{
            "assigned_to_id" => nil,
            "dob" => "2000-01-01",
            "external_id" => "10000",
            "fingerprint" => "2000-01-01 version-1 testuser",
            "first_name" => "Version-1",
            "last_name" => "Testuser",
            "originator" => %{"id" => user.id},
            "preferred_language" => "English",
            "tid" => "version-1"
          },
          by: "user"
        ]
      ])

      person
      |> Cases.change_person(%{tid: person.tid})
      |> Repo.Versioned.update!()
      |> assert_versions([
        [
          change: %{
            "assigned_to_id" => nil,
            "dob" => "2000-01-01",
            "external_id" => "10000",
            "fingerprint" => "2000-01-01 version-1 testuser",
            "first_name" => "Version-1",
            "last_name" => "Testuser",
            "originator" => %{"id" => user.id},
            "preferred_language" => "English",
            "tid" => "version-1"
          },
          by: "user"
        ]
      ])
    end

    test "all_versions returns all versions sorted by id desc", %{person_changeset: person_changeset, user: user} do
      person = person_changeset |> Repo.Versioned.insert!()

      person
      |> Cases.Person.changeset(%{tid: "version-2"})
      |> Repo.Versioned.update!()

      person
      |> assert_versions([
        [change: %{"tid" => "version-2"}, by: "user"],
        [
          change: %{
            "assigned_to_id" => nil,
            "dob" => "2000-01-01",
            "external_id" => "10000",
            "fingerprint" => "2000-01-01 version-1 testuser",
            "first_name" => "Version-1",
            "last_name" => "Testuser",
            "originator" => %{"id" => user.id},
            "preferred_language" => "English",
            "tid" => "version-1"
          },
          by: "user"
        ]
      ])
    end

    test "last_version returns most recent version", %{person_changeset: person_changeset, user: user} do
      person = person_changeset |> Repo.Versioned.insert!()

      person
      |> Repo.Versioned.last_version()
      |> assert_version(
        change: %{
          "assigned_to_id" => nil,
          "dob" => "2000-01-01",
          "external_id" => "10000",
          "fingerprint" => "2000-01-01 version-1 testuser",
          "first_name" => "Version-1",
          "last_name" => "Testuser",
          "originator" => %{"id" => user.id},
          "preferred_language" => "English",
          "tid" => "version-1"
        },
        by: "user"
      )

      person
      |> Cases.Person.changeset(%{tid: "version-2"})
      |> Repo.Versioned.update!()

      person
      |> Repo.Versioned.last_version()
      |> assert_version(change: %{"tid" => "version-2"}, by: "user")
    end

    test "originated_by sets the originator", %{person_changeset: person_changeset} do
      new_user = Test.Fixtures.user_attrs("new_user") |> Accounts.create_user!()
      new_changeset = Repo.Versioned.with_originator(person_changeset, new_user)
      assert Repo.Versioned.get_originator!(new_changeset) == new_user
    end
  end
end
