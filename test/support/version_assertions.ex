defmodule Epicenter.Test.VersionAssertions do
  import Euclid.Test.Extra.Assertions
  import ExUnit.Assertions

  alias Epicenter.Accounts
  alias Epicenter.Repo

  def assert_version(schema, expected) do
    schema |> describe_version() |> assert_eq(expected)
  end

  def assert_versions(schema, expected) do
    schema |> describe_versions() |> assert_eq(expected)
  end

  def assert_last_version(schema, expected) do
    assert describe_last_version(schema) == expected
  end

  def assert_versioned(schema) do
    if Repo.Versioned.last_version(schema) == nil, do: flunk("Expected schema to have a version, but found none.")
  end

  def assert_versioned(schema, expected_count: expected_count) do
    version_count = schema |> Repo.Versioned.all_versions() |> length()
    if version_count != expected_count, do: flunk("Expected schema to have #{expected_count} version(s), but found #{version_count}.")
  end

  # # #

  defp describe_last_version(schema), do: schema |> Repo.Versioned.last_version() |> describe_version()

  defp describe_version(version),
    do: [
      change: version.item_changes |> Map.drop(["id", "inserted_at", "seq", "updated_at"]),
      by: Accounts.get_user(version.originator_id).tid
    ]

  defp describe_versions({:ok, schema}),
    do: schema |> describe_versions()

  defp describe_versions(schema),
    do: schema |> Repo.Versioned.all_versions() |> Enum.map(&describe_version/1)
end
