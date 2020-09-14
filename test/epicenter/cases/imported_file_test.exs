defmodule Epicenter.Cases.ImportedFileTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Cases
  alias Epicenter.Cases.ImportedFile
  alias Epicenter.Test

  describe "schema" do
    test "fields" do
      assert_schema(
        ImportedFile,
        [
          {:id, :id},
          {:inserted_at, :naive_datetime},
          {:seq, :integer},
          {:tid, :string},
          {:updated_at, :naive_datetime},
          {:file_name, :string},
          {:contents, :text}
        ]
      )
    end
  end

  describe "changeset" do
    test "file_name is required" do
      ImportedFile.changeset(
        %ImportedFile{},
        Test.Fixtures.imported_file_attrs("created file", %{file_name: nil})
      )
      |> assert_invalid()
    end
  end

  describe "create_imported_file" do
    import Euclid.Extra.Enum, only: [tids: 1]

    test "it creates the file" do
      Test.Fixtures.imported_file_attrs("created file")
      |> Cases.create_imported_file()

      ImportedFile.Query.all() |> Repo.all() |> tids() |> assert_eq(["created file"])
    end
  end
end