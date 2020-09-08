defmodule Epicenter.Cases.AssignmentTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Cases

  describe "schema" do
    test "fields" do
      assert_schema(
        Cases.Assignment,
        [
          {:id, :id},
          {:inserted_at, :naive_datetime},
          {:person_id, :id},
          {:seq, :integer},
          {:tid, :string},
          {:updated_at, :naive_datetime},
          {:user_id, :id}
        ]
      )
    end
  end
end
