defmodule Epicenter.Validation do
  import Ecto.Changeset, only: [validate_change: 3]

  @user_input_restrictions Application.compile_env(:epicenter, :user_input_restrictions, :testdata_only)

  def validate_phi(changeset, validation_set, user_input_restrictions \\ @user_input_restrictions)

  def validate_phi(changeset, validation_set, :testdata_only),
    do: validate(changeset, validation_set)

  def validate_phi(changeset, _validation_set, :unrestricted),
    do: changeset

  defp validate(changeset, :person) do
    changeset
    |> validate_change(:last_name, &last_name_validator/2)
    |> validate_change(:dob, &date_validator/2)
  end

  defp validate(changeset, :address) do
    changeset
    |> validate_change(:full_address, &address_full_address_validator/2)
  end

  defp validate(changeset, :phone) do
    changeset
    |> validate_change(:number, &phone_number_validator/2)
  end

  defp validate(changeset, :email) do
    changeset
    |> validate_change(:address, &email_address_validator/2)
  end

  # # #

  @four_digits_followed_by_fake_address ~r|\d{4} Test St, City, TS 00000|
  @seven_leading_ones_followed_by_three_digits ~r|1{7}\d+|

  defp date_validator(field, date) do
    if date.day == 1,
      do: valid(),
      else: invalid(field, "must be the first of the month")
  end

  defp last_name_validator(field, value) do
    if value |> String.starts_with?("Testuser"),
      do: valid(),
      else: invalid(field, "must start with 'Testuser'")
  end

  defp address_full_address_validator(field, value) do
    if value =~ @four_digits_followed_by_fake_address,
      do: valid(),
      else: invalid(field, "must match '#### Test St, City, TS 00000'")
  end

  defp phone_number_validator(field, value) do
    if value =~ @seven_leading_ones_followed_by_three_digits,
      do: valid(),
      else: invalid(field, "must match '111-111-1xxx'")
  end

  defp email_address_validator(field, value) do
    if value |> String.ends_with?("@example.com"),
      do: valid(),
      else: invalid(field, "must end with '@example.com'")
  end

  defp valid(), do: []
  defp invalid(field, message), do: [{field, "In non-PHI environment, #{message}"}]
end
