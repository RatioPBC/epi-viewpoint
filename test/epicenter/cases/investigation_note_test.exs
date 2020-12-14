defmodule Epicenter.Cases.InvestigationNoteTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Cases.InvestigationNote
  alias Epicenter.Repo
  alias Epicenter.Test

  setup :persist_admin
  @admin Test.Fixtures.admin()

  describe "schema" do
    test "fields" do
      assert_schema(
        InvestigationNote,
        [
          {:author_id, :binary_id},
          {:id, :binary_id},
          {:inserted_at, :utc_datetime},
          {:case_investigation_id, :binary_id},
          {:deleted_at, :utc_datetime},
          {:exposure_id, :binary_id},
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
        InvestigationNote.changeset(%InvestigationNote{}, %{
          author_id: user.id,
          case_investigation_id: case_investigation.id,
          text: "foo",
          tid: "case_investigation_note"
        })
        |> Repo.insert!()

      assert note |> Repo.preload(:case_investigation) |> Map.get(:case_investigation) |> Map.get(:tid) == "investigation"
    end

    test "belongs to exposure" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      lab_result = Test.Fixtures.lab_result_attrs(alice, user, "lab_result", ~D[2020-10-29]) |> Cases.create_lab_result!()
      case_investigation = Test.Fixtures.case_investigation_attrs(alice, lab_result, user, "case_investigation") |> Cases.create_case_investigation!()

      {:ok, exposure} =
        {
          Test.Fixtures.case_investigation_exposure_attrs(case_investigation, "contact_investigation"),
          Test.Fixtures.admin_audit_meta()
        }
        |> Cases.create_contact_investigation()

      note =
        InvestigationNote.changeset(%InvestigationNote{}, %{
          author_id: user.id,
          exposure_id: exposure.id,
          text: "foo",
          tid: "case_investigation_note"
        })
        |> Repo.insert!()

      assert note |> Repo.preload(:exposure) |> Map.get(:exposure) |> Map.get(:tid) == "contact_investigation"
    end
  end
end
