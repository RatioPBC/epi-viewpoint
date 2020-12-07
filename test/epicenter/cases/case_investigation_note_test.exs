defmodule Epicenter.Cases.CaseInvestigationNoteTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Cases.CaseInvestigationNote
  alias Epicenter.Repo
  alias Epicenter.Test

  setup :persist_admin
  @admin Test.Fixtures.admin()

  describe "schema" do
    test "fields" do
      assert_schema(
        CaseInvestigationNote,
        [
          {:author_id, :binary_id},
          {:id, :binary_id},
          {:inserted_at, :utc_datetime},
          {:case_investigation_id, :binary_id},
          {:deleted_at, :utc_datetime},
          {:seq, :integer},
          {:tid, :string},
          {:text, :string},
          {:updated_at, :utc_datetime}
        ]
      )
    end

    test "belongs to case investigation" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      lab_result = Test.Fixtures.lab_result_attrs(alice, user, "lab_result", ~D[2020-10-29]) |> Cases.create_lab_result!()
      case_investigation = Test.Fixtures.case_investigation_attrs(alice, lab_result, user, "investigation") |> Cases.create_case_investigation!()

      note =
        CaseInvestigationNote.changeset(%CaseInvestigationNote{}, %{
          author_id: user.id,
          case_investigation_id: case_investigation.id,
          text: "foo",
          tid: "case_investigation_note"
        })
        |> Repo.insert!()

      assert note |> Repo.preload(:case_investigation) |> Map.get(:case_investigation) |> Map.get(:tid) == "investigation"
    end
  end
end
