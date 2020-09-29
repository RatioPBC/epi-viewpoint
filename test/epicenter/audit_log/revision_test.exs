defmodule Epicenter.AuditLog.RevisionTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.AuditLog.Revision
  alias Epicenter.Test

  describe "schema" do
    test "fields" do
      assert_schema(
        Revision,
        [
          {:after_change, :map},
          {:author_id, :id},
          {:before_change, :map},
          {:change, :map},
          {:changed_id, :string},
          {:changed_type, :string},
          {:id, :id},
          {:inserted_at, :naive_datetime},
          {:reason_action, :string},
          {:reason_event, :string},
          {:seq, :integer},
          {:tid, :string},
        ]
      )
    end
  end

  describe "changeset" do
    defp new_changeset(attr_updates) do
      default_attrs = Test.Fixtures.revision_attrs("revision_tid")
      Revision.changeset(%Revision{}, Map.merge(default_attrs, attr_updates |> Enum.into(%{})))
    end

    test "attributes" do
      author_id = Ecto.UUID.generate()
      changeset = new_changeset(%{tid: "revision", author_id: author_id}).changes
      assert changeset.author_id == author_id
      assert changeset.changed_type == "Epicenter.Cases.Person"
      assert changeset.reason_action == "reason_action"
      assert changeset.reason_event == "reason_event"
    end

    test "after_change is required", do: assert_invalid(new_changeset(after_change: nil))
    test "author_id is required", do:  assert_invalid(new_changeset(author_id: nil))
    test "before_change is required", do:  assert_invalid(new_changeset(before_change: nil))
    test "change is required", do:  assert_invalid(new_changeset(change: nil))
    test "changed_id is required", do:  assert_invalid(new_changeset(changed_id: nil))
    test "changed_type is required", do:  assert_invalid(new_changeset(changed_type: nil))
    test "reason_action is required", do:  assert_invalid(new_changeset(reason_action: nil))
    test "reason_event is required", do:  assert_invalid(new_changeset(reason_event: nil))
  end
end
