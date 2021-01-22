defmodule Epicenter.Cases.MergeTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Cases.Merge
  alias Epicenter.Test

  setup :persist_admin
  @admin Test.Fixtures.admin()

  setup do
    user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()

    catie = Test.Fixtures.person_attrs(user, "catie") |> Cases.create_person!()
    katie = Test.Fixtures.person_attrs(user, "katie") |> Cases.create_person!()
    katy = Test.Fixtures.person_attrs(user, "katy") |> Cases.create_person!()

    [catie: catie, katie: katie, katy: katy, user: user]
  end

  describe "merge_conflicts" do
    test "it identifies and returns the unique values for the 3 fields of interest",
         %{catie: catie, katie: katie, katy: katy, user: user} do
      conflicts = Merge.merge_conflicts([catie.id, katie.id, katy.id], user)
      assert conflicts == %{unique_first_names: ["Catie", "Katie", "Katy"]}
    end
  end
end
