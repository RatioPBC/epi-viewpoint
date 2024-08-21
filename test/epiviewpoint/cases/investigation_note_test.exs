defmodule EpiViewpoint.Cases.InvestigationNoteTest do
  use EpiViewpoint.DataCase, async: true

  alias EpiViewpoint.Accounts
  alias EpiViewpoint.Cases
  alias EpiViewpoint.Cases.InvestigationNote
  alias EpiViewpoint.ContactInvestigations
  alias EpiViewpoint.Repo
  alias EpiViewpoint.Test

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
          {:contact_investigation_id, :binary_id},
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

    test "belongs to contact investigation" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      lab_result = Test.Fixtures.lab_result_attrs(alice, user, "lab_result", ~D[2020-10-29]) |> Cases.create_lab_result!()
      case_investigation = Test.Fixtures.case_investigation_attrs(alice, lab_result, user, "case_investigation") |> Cases.create_case_investigation!()

      {:ok, contact_investigation} =
        {
          Test.Fixtures.contact_investigation_attrs("contact_investigation", %{exposing_case_id: case_investigation.id}),
          Test.Fixtures.admin_audit_meta()
        }
        |> ContactInvestigations.create()

      note =
        InvestigationNote.changeset(%InvestigationNote{}, %{
          author_id: user.id,
          contact_investigation_id: contact_investigation.id,
          text: "foo",
          tid: "case_investigation_note"
        })
        |> Repo.insert!()

      assert note |> Repo.preload(:contact_investigation) |> Map.get(:contact_investigation) |> Map.get(:tid) == "contact_investigation"
    end
  end
end
