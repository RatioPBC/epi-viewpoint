defmodule Epicenter.Test.RevisionAssertions do
  # import Euclid.Test.Extra.Assertions
  import ExUnit.Assertions

  def assert_audit_logged(%{id: model_id}) do
    if Epicenter.AuditLog.entries_for(model_id) == [], do: flunk("Expected schema to have an audit log entry, but found none.")
  end

  def assert_revision_count(%{id: model_id}, count) do
    entries = Epicenter.AuditLog.entries_for(model_id)
    if length(entries) != count, do: flunk("Expected #{count} revisions but found #{length(entries)}")
  end

  def assert_recent_audit_log(%{id: model_id}, author, change) do
    entry = Epicenter.AuditLog.entries_for(model_id) |> List.last()
    if entry == nil, do: flunk("Expected schema to have an audit log entry, but found none.")
    if entry.author_id != author.id, do: flunk("Expected revision to have author #{author.tid} but it did not")
    assert ^change = Map.take(entry.change, Map.keys(change))
  end
end
