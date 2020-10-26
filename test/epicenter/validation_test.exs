defmodule Epicenter.ValidationTest do
  use Epicenter.SimpleCase, async: true

  import Epicenter.Test.ChangesetAssertions

  alias Ecto.Changeset
  alias Epicenter.Validation

  describe "validate_date" do
    defmodule TestSchema do
      use Ecto.Schema

      schema "test_schema" do
        field :start_date, :string
      end
    end

    defp validate(date_string),
      do: %TestSchema{} |> Changeset.change(start_date: date_string) |> Validation.validate_date(:start_date)

    test "allows month/day/year and month-day-year" do
      "01/02/2020" |> validate() |> assert_valid()
      "1/2/2020" |> validate() |> assert_valid()
      "1/2/20" |> validate() |> assert_valid()

      "01-02-2020" |> validate() |> assert_valid()
      "1-2-2020" |> validate() |> assert_valid()
      "1-2-20" |> validate() |> assert_valid()
    end

    test "doesn't allow other things" do
      "Jan 2 2020" |> validate() |> assert_invalid(start_date: ["must be MM/DD/YYYY"])
      "2020-01-02" |> validate() |> assert_invalid(start_date: ["must be MM/DD/YYYY"])
      "mmm... pie" |> validate() |> assert_invalid(start_date: ["must be MM/DD/YYYY"])
    end
  end
end
