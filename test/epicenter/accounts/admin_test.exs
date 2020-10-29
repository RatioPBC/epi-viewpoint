defmodule Epicenter.Accounts.AdminTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Accounts
  alias Epicenter.Accounts.Admin
  alias Epicenter.Accounts.User
  alias Epicenter.Cases
  alias Epicenter.Cases.Person
  alias Epicenter.Repo
  alias Epicenter.Test

  setup do
    {:ok, persisted_admin} = Test.Fixtures.admin() |> Accounts.change_user(%{}) |> Repo.insert()
    unpersisted_admin = %User{id: Application.get_env(:epicenter, :unpersisted_admin_id)}
    {:ok, not_admin} = Test.Fixtures.user_attrs(unpersisted_admin, "not-admin") |> Accounts.register_user()
    {person_attrs, audit_meta} = Test.Fixtures.person_attrs(persisted_admin, "person")

    %{
      audit_meta: audit_meta,
      person_attrs: person_attrs,
      not_admin: not_admin,
      persisted_admin: persisted_admin,
      unpersisted_admin: unpersisted_admin
    }
  end

  describe "persisted_admin? and unpersisted_admin?" do
    test "for persisted admin", %{audit_meta: audit_meta, persisted_admin: persisted_admin} do
      audit_meta = %{audit_meta | author_id: persisted_admin.id}
      assert Admin.persisted_admin?(audit_meta)
      refute Admin.unpersisted_admin?(audit_meta)
    end

    test "for unpersisted admin", %{audit_meta: audit_meta, unpersisted_admin: unpersisted_admin} do
      audit_meta = %{audit_meta | author_id: unpersisted_admin.id}
      refute Admin.persisted_admin?(audit_meta)
      assert Admin.unpersisted_admin?(audit_meta)
    end

    test "for non-admin", %{audit_meta: audit_meta, not_admin: not_admin} do
      audit_meta = %{audit_meta | author_id: not_admin.id}
      refute Admin.persisted_admin?(audit_meta)
      refute Admin.unpersisted_admin?(audit_meta)
    end
  end

  describe "insert_by_admin and insert_by_admin!" do
    test "succeeds when the author is a persisted admin",
         %{persisted_admin: persisted_admin, person_attrs: person_attrs, audit_meta: audit_meta} do
      audit_meta = %{audit_meta | author_id: persisted_admin.id}

      {:ok, inserted1} = Cases.change_person(%Person{}, person_attrs) |> Admin.insert_by_admin(audit_meta)
      assert inserted1.tid == "person"
      assert_revision_count(inserted1, 1)

      inserted2 = Cases.change_person(%Person{}, person_attrs) |> Admin.insert_by_admin!(audit_meta)
      assert inserted2.tid == "person"
      assert_revision_count(inserted2, 1)
    end

    test "succeeds when the author is an unpersisted admin",
         %{unpersisted_admin: unpersisted_admin, person_attrs: person_attrs, audit_meta: audit_meta} do
      audit_meta = %{audit_meta | author_id: unpersisted_admin.id}

      {:ok, inserted1} = Cases.change_person(%Person{}, person_attrs) |> Admin.insert_by_admin(audit_meta)
      assert inserted1.tid == "person"
      assert_revision_count(inserted1, 1)

      inserted2 = Cases.change_person(%Person{}, person_attrs) |> Admin.insert_by_admin!(audit_meta)
      assert inserted2.tid == "person"
      assert_revision_count(inserted2, 1)
    end

    test "fails when the author is not an admin",
         %{not_admin: not_admin, person_attrs: person_attrs, audit_meta: audit_meta} do
      audit_meta = %{audit_meta | author_id: not_admin.id}

      {:error, :admin_privileges_required} = Cases.change_person(%Person{}, person_attrs) |> Admin.insert_by_admin(audit_meta)

      assert_raise Epicenter.AdminRequiredError, "Action can only be performed by administrators", fn ->
        Cases.change_person(%Person{}, person_attrs) |> Admin.insert_by_admin!(audit_meta)
      end
    end
  end

  describe "update_by_admin" do
    test "succeeds when the author is a persisted admin",
         %{persisted_admin: persisted_admin, person_attrs: person_attrs, audit_meta: audit_meta} do
      audit_meta = %{audit_meta | author_id: persisted_admin.id}
      {:ok, person} = Cases.create_person({person_attrs, audit_meta})

      {:ok, updated} = Cases.change_person(person, %{tid: "updated"}) |> Admin.update_by_admin(audit_meta)
      assert updated.tid == "updated"
      assert_revision_count(updated, 2)
    end

    test "fails when the author is an unpersisted admin",
         %{unpersisted_admin: unpersisted_admin, person_attrs: person_attrs, audit_meta: audit_meta} do
      audit_meta = %{audit_meta | author_id: unpersisted_admin.id}
      {:ok, person} = Cases.create_person({person_attrs, audit_meta})

      {:error, :admin_privileges_required} = Cases.change_person(person, %{tid: "updated"}) |> Admin.update_by_admin(audit_meta)
    end

    test "fails when the author is not an admin",
         %{not_admin: not_admin, person_attrs: person_attrs, audit_meta: audit_meta} do
      audit_meta = %{audit_meta | author_id: not_admin.id}
      {:ok, person} = Cases.create_person({person_attrs, audit_meta})

      {:error, :admin_privileges_required} = Cases.change_person(person, %{tid: "updated"}) |> Admin.update_by_admin(audit_meta)
    end
  end
end
