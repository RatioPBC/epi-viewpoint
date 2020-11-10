defmodule Epicenter.Validation do
  alias Ecto.Changeset
  alias Epicenter.DateParser

  def validate_date(changeset, field) when is_atom(field) do
    Changeset.validate_change(changeset, field, fn field, date ->
      case DateParser.parse_mm_dd_yyyy(date) do
        {:ok, _} -> valid()
        {:error, _} -> invalid(field, "must be a valid MM/DD/YYYY date")
      end
    end)
  end

  def validate_email_format(changeset, field) do
    changeset
    |> Changeset.validate_format(field, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> Changeset.validate_length(field, max: 160)
  end

  defp valid(), do: []
  defp invalid(field, message), do: [{field, message}]
end
