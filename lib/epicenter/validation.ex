defmodule Epicenter.Validation do
  import Ecto.Changeset, only: [validate_change: 3]

  @four_digits_followed_by_fake_address ~r|\d{4} Test St, City, TS 00000|
  @seven_leading_ones_followed_by_three_digits ~r|1{7}\d{3}|

  def validate_phi(changeset, :person) do
    changeset
    |> validate_change(:last_name, &last_name_validator/2)
    |> validate_change(:dob, &date_validator/2)
  end

  def validate_phi(changeset, :address) do
    changeset
    |> validate_change(:full_address, &address_full_address_validator/2)
  end

  def validate_phi(changeset, :phone) do
    changeset
    |> validate_change(:number, &phone_number_validator/2)
  end

  def validate_phi(changeset, :email) do
    changeset
    |> validate_change(:address, &email_address_validator/2)
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

  defp address_full_address_validator(field, value) do
    if value =~ @four_digits_followed_by_fake_address,
      do: [],
      else: [{field, "In non-PHI environment, must match '#### Test St, City, TS 00000'"}]
  end

  defp phone_number_validator(field, value) do
    if to_string(value) =~ @seven_leading_ones_followed_by_three_digits,
      do: [],
      else: [{field, "In non-PHI environment, must match '111-111-1xxx'"}]
  end

  defp email_address_validator(field, value) do
    if value |> String.ends_with?("@example.com"),
      do: [],
      else: [{field, "In non-PHI environment, must end with '@example.com'"}]
  end
end
