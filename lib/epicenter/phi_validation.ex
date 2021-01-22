defmodule Epicenter.PhiValidation do
  import Ecto.Changeset, only: [validate_change: 3]

  @user_input_restrictions Application.compile_env(:epicenter, :user_input_restrictions, :testdata_only)

  def validate_phi(changeset, validation_set, user_input_restrictions \\ @user_input_restrictions)

  def validate_phi(changeset, validation_set, :testdata_only),
    do: validate(changeset, validation_set)

  def validate_phi(changeset, _validation_set, :unrestricted),
    do: changeset

  defp validate(changeset, :demographic) do
    changeset
    |> validate_change(:last_name, &last_name_validator/2)
    |> validate_change(:dob, &date_validator/2)
  end

  defp validate(changeset, :address) do
    changeset
    |> validate_change(:street, &address_street_validator/2)
    |> validate_change(:city, &address_city_validator/2)
    |> validate_change(:postal_code, &address_postal_code_validator/2)
  end

  defp validate(changeset, :phone) do
    changeset
    |> validate_change(:number, &phone_number_validator/2)
  end

  defp validate(changeset, :email) do
    changeset
    |> validate_change(:address, &email_address_validator/2)
  end

  defp validate(changeset, :contact_investigation) do
    changeset
    |> validate_change(:guardian_phone, &phone_number_validator/2)
  end

  defp validate(changeset, :contact_investigation_form) do
    changeset
    |> validate_change(:last_name, &last_name_validator/2)
    |> validate_change(:guardian_phone, &phone_number_validator/2)
  end

  # # #

  @four_digits_followed_by_fake_street ~r|\A\d{4} Test St\z|
  @city_followed_by_numbers ~r|\ACity\d*\z|
  @four_leading_zeroes_followed_by_one_digit ~r|\A0000\d\z|
  @seven_leading_ones_followed_by_three_digits ~r|1{7}\d+|

  defp date_validator(field, date) do
    if date.day == 1,
      do: valid(),
      else: invalid(field, "must be the first of the month")
  end

  defp last_name_validator(field, value) do
    if value |> String.downcase() |> String.starts_with?("testuser"),
      do: valid(),
      else: invalid(field, "must start with 'Testuser'")
  end

  defp address_street_validator(field, value) do
    if value =~ @four_digits_followed_by_fake_street,
      do: valid(),
      else: invalid(field, "must match '#### Test St'")
  end

  defp address_city_validator(field, value) do
    if value =~ @city_followed_by_numbers,
      do: valid(),
      else: invalid(field, "must match 'City#'")
  end

  defp address_postal_code_validator(field, value) do
    if value =~ @four_leading_zeroes_followed_by_one_digit,
      do: valid(),
      else: invalid(field, "must match '0000x'")
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
