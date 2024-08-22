defmodule EpiViewpoint.Cases.ImportedFileTest do
  use EpiViewpoint.DataCase, async: true

  alias EpiViewpoint.Accounts
  alias EpiViewpoint.Cases
  alias EpiViewpoint.Cases.ImportedFile
  alias EpiViewpoint.Test

  setup :persist_admin
  @admin Test.Fixtures.admin()

  describe "schema" do
    test "fields" do
      assert_schema(
        ImportedFile,
        [
          {:id, :binary_id},
          {:inserted_at, :utc_datetime},
          {:seq, :integer},
          {:tid, :string},
          {:updated_at, :utc_datetime},
          {:file_name, :string},
          {:contents, :string}
        ]
      )
    end
  end

  describe "changeset" do
    test "file_name is required" do
      creator = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()

      {attrs, _} = Test.Fixtures.imported_file_attrs(creator, "created file", %{file_name: nil})

      ImportedFile.changeset(
        %ImportedFile{},
        attrs
      )
      |> assert_invalid()
    end
  end

  describe "create_imported_file" do
    import Euclid.Extra.Enum, only: [tids: 1]

    setup do
      creator = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()

      %{creator: creator}
    end

    test "it creates the file", %{creator: creator} do
      Test.Fixtures.imported_file_attrs(creator, "created file")
      |> Cases.create_imported_file()

      ImportedFile.Query.all() |> Repo.all() |> tids() |> assert_eq(["created file"])
    end

    test "has a revision count", %{creator: creator} do
      imported_file =
        Test.Fixtures.imported_file_attrs(creator, "created file")
        |> Cases.create_imported_file()

      assert_revision_count(imported_file, 1)
    end

    test "has an audit log", %{creator: creator} do
      imported_file =
        Test.Fixtures.imported_file_attrs(creator, "created file", %{contents: "file contents"})
        |> Cases.create_imported_file()

      assert_recent_audit_log(imported_file, creator, %{
        "tid" => "created file",
        "file_name" => "test_results_september_14_2020",
        "contents" => "<<REDACTED>>"
      })

      refute EpiViewpoint.AuditingRepo.entries_for(imported_file.id) |> List.last() |> Map.get(:after_change) |> Map.has_key?("seq")
    end
  end
end
