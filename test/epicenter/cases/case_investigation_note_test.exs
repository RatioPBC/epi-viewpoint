defmodule Epicenter.Cases.CaseInvestigationNoteTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Cases

  setup :persist_admin

  describe "schema" do
    test "fields" do
      assert_schema(
        Cases.CaseInvestigationNote,
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
  end
end
