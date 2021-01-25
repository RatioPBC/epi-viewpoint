defmodule Epicenter.Cases.MergeTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Cases.Merge
  alias Epicenter.Test

  setup :persist_admin
  @admin Test.Fixtures.admin()

  defp create_person(user, tid, first_name) do
    Test.Fixtures.person_attrs(user, tid, %{demographics: [%{first_name: first_name}]}, demographics: true) |> Cases.create_person!()
  end

  setup do
    user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()

    person_ids =
      [{"catie", "Catie"}, {"catie2", "catie"}, {"katie", "Katie"}, {"katie2", "Katie"}, {"katy", "Katy"}]
      |> Enum.map(fn {tid, first_name} -> create_person(user, tid, first_name) end)
      |> Enum.map(& &1.id)

    [person_ids: person_ids, user: user]
  end

  describe "merge_conflicts" do
    test "it identifies and returns the unique values for the 3 fields of interest", %{person_ids: person_ids, user: user} do
      conflicts = Merge.merge_conflicts(person_ids, user, [:first_name])
      assert conflicts == %{first_name: ["Catie", "catie", "Katie", "Katy"]}
    end
  end
end
