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

  def assert_recent_audit_log(model, author, change) do
    entry = recent_audit_log(model)
    if entry == nil, do: flunk("Expected schema to have an audit log entry, but found none.")
    if entry.author_id != author.id, do: flunk("Expected revision to have author #{author.tid} but it did not")
    assert ^change = Map.take(entry.change |> remove_ids(), Map.keys(change))
  end

  def assert_recent_audit_log_snapshots(model, author, expected_before, expected_after) do
    entry = recent_audit_log(model)
    if entry == nil, do: flunk("Expected schema to have an audit log entry, but found none.")
    if entry.author_id != author.id, do: flunk("Expected revision to have author #{author.tid} but it did not")
    assert ^expected_before = Map.take(entry.before_change |> remove_ids(), Map.keys(expected_before))
    assert ^expected_after = Map.take(entry.after_change |> remove_ids(), Map.keys(expected_after))
  end

  def recent_audit_log(%{id: model_id}) do
    Epicenter.AuditLog.entries_for(model_id) |> List.last()
  end

  defp remove_ids(map) when is_map(map) do
    map
    |> Map.drop(["id"])
    |> Enum.map(fn {k, v} -> {k, remove_ids(v)} end)
    |> Enum.into(%{})
  end

  defp remove_ids(list) when is_list(list), do: Enum.map(list, &remove_ids/1)
  defp remove_ids(other), do: other
end
