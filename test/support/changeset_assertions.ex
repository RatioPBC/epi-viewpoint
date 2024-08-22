defmodule EpiViewpoint.Test.ChangesetAssertions do
  import ExUnit.Assertions

  alias EpiViewpoint.DataCase

  def assert_invalid(tuple_or_changeset, expected_errors \\ nil)

  def assert_invalid({:error, %Ecto.Changeset{} = changeset}, expected_errors),
    do: assert_invalid(changeset, expected_errors)

  def assert_invalid({:ok, _} = arg, _expected_errors),
    do: flunk("Got an {:ok, _} tuple, expected an {:error, _} tuple or no tuple:\n#{inspect(arg)}")

  def assert_invalid(%Ecto.Changeset{valid?: true}, _expected_errors),
    do: flunk("Expected changeset to be invalid but it was valid.")

  def assert_invalid(%Ecto.Changeset{valid?: false} = changeset, nil = _expected_errors),
    do: changeset

  def assert_invalid(%Ecto.Changeset{valid?: false} = changeset, expected_errors) do
    assert(DataCase.errors_on(changeset) == Enum.into(expected_errors, %{}))
    changeset
  end

  def assert_valid(%Ecto.Changeset{valid?: false} = changeset),
    do: flunk("Expected changeset to be valid, but it was invalid:\n#{inspect(DataCase.errors_on(changeset))}")

  def assert_valid(%Ecto.Changeset{valid?: true} = changeset),
    do: changeset
end
