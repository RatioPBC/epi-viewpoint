defmodule Epicenter.Test.ChangesetAssertions do
  import ExUnit.Assertions

  def assert_invalid({:error, %Ecto.Changeset{} = changeset}) do
    assert_invalid(changeset)
  end

  def assert_invalid({:ok, _} = arg) do
    flunk("Got an {:ok, _} tuple, expected an {:error, _} tuple or no tuple:\n#{inspect(arg)}")
  end

  def assert_invalid(%Ecto.Changeset{} = changeset) do
    if changeset.valid? do
      flunk("Expected changeset to be invalid but it was valid.")
    end
  end

  def assert_valid(%Ecto.Changeset{} = changeset) do
    if !changeset.valid? do
      flunk("Expected changeset to be valid, but it was invalid and had the following errors:\n#{inspect(changeset.errors)}")
    end
  end
end
