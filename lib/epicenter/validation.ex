defmodule Epicenter.Validation do
  import Ecto.Changeset, only: [validate_change: 3]

  def validate_phi(changeset, :person) do
    changeset
    |> validate_change(:last_name, &last_name_validator/2)
    |> validate_change(:dob, &date_validator/2)
  end

  def validate_phi(changeset, :phone) do
    changeset
    |> validate_change(:number, &phone_number_validator/2)
  end

  defp date_validator(field, date) do
    if date.day == 1,
      do: [],
      else: [{field, "In non-PHI environment, must be the first of the month"}]
  end

  defp last_name_validator(field, value) do
    if value == "Testuser",
      do: [],
      else: [{field, "In non-PHI environment, must be equal to 'Testuser'"}]
  end

  defp phone_number_validator(field, value) do
    if rem(value, 10000) == 1000,
      do: [],
      else: [{field, "In non-PHI environment, must end with '1000'"}]
  end
end
