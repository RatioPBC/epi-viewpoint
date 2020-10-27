defmodule Epicenter.Cases.DemographicTest do
  use Epicenter.DataCase, async: true
  alias Epicenter.Cases.Demographic

  defp new_changeset(attr_updates) do
    Demographic.changeset(%Demographic{}, attr_updates)
  end

  test "validates personal health information on dob", do: assert_invalid(new_changeset(%{dob: "01-10-2000"}))
  test "validates personal health information on last_name", do: assert_invalid(new_changeset(%{last_name: "Aliceblat"}))
end
