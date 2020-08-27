defmodule Epicenter.Test.VersionAssertions do
  import ExUnit.Assertions
  alias Epicenter.Repo

  def assert_versioned(schema) do
    if Repo.Versioned.last_version(schema) == nil, do: flunk("Expected schema to have a version, but found none.")
  end

  def assert_versioned(schema, expected_count: expected_count) do
    version_count = schema |> Repo.Versioned.all_versions() |> length()
    if version_count != expected_count, do: flunk("Expected schema to have #{expected_count} version(s), but found #{version_count}.")
  end
end
