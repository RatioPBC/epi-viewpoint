defmodule Epicenter.ValidationTest do
  use Epicenter.SimpleCase, async: true

  import Epicenter.Test.ChangesetAssertions

  alias Ecto.Changeset
  alias Epicenter.Validation

  defmodule TestSchema do
    use Ecto.Schema

    schema "test_schema" do
      field :start_date, :string
      field :email, :string
    end
  end

  defp change_start_date(date_string),
    do: %TestSchema{} |> Changeset.change(start_date: date_string)

  defp change_email(email),
    do: %TestSchema{} |> Changeset.change(email: email)

  describe "validate_date" do
    test "allows month/day/year and month-day-year" do
      "01/02/2020" |> change_start_date() |> Validation.validate_date(:start_date) |> assert_valid()
      "1/2/2020" |> change_start_date() |> Validation.validate_date(:start_date) |> assert_valid()
      "1/2/20" |> change_start_date() |> Validation.validate_date(:start_date) |> assert_valid()

      "01-02-2020" |> change_start_date() |> Validation.validate_date(:start_date) |> assert_valid()
      "1-2-2020" |> change_start_date() |> Validation.validate_date(:start_date) |> assert_valid()
      "1-2-20" |> change_start_date() |> Validation.validate_date(:start_date) |> assert_valid()
    end

    test "doesn't allow other things" do
      "Jan 2 2020" |> change_start_date() |> Validation.validate_date(:start_date) |> assert_invalid(start_date: ["please enter dates as mm/dd/yyyy"])
      "2020-01-02" |> change_start_date() |> Validation.validate_date(:start_date) |> assert_invalid(start_date: ["please enter dates as mm/dd/yyyy"])
      "mmm... pie" |> change_start_date() |> Validation.validate_date(:start_date) |> assert_invalid(start_date: ["please enter dates as mm/dd/yyyy"])
    end
  end

  describe "validate_email_format" do
    test "requires an @ sign in the middle and no spaces" do
      "user@example.com" |> change_email() |> Validation.validate_email_format(:email) |> assert_valid()
      "a@b.com" |> change_email() |> Validation.validate_email_format(:email) |> assert_valid()
    end

    test "doesn't allow other things" do
      "user at example.com"
      |> change_email()
      |> Validation.validate_email_format(:email)
      |> assert_invalid(email: ["must have the @ sign and no spaces"])

      "@example.com" |> change_email() |> Validation.validate_email_format(:email) |> assert_invalid(email: ["must have the @ sign and no spaces"])
      "user@" |> change_email() |> Validation.validate_email_format(:email) |> assert_invalid(email: ["must have the @ sign and no spaces"])
    end

    test "cannot be longer than 160 chars" do
      ("user@" <> String.duplicate("x", 200))
      |> change_email()
      |> Validation.validate_email_format(:email)
      |> assert_invalid(email: ["should be at most 160 character(s)"])
    end
  end
end
