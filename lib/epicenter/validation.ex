defmodule Epicenter.Validation do
  import Ecto.Changeset, only: [validate_change: 3]

  alias Epicenter.DateParser

  def validate_date(changeset, field) when is_atom(field) do
    validate_change(changeset, field, fn field, date ->
      case DateParser.parse_mm_dd_yyyy(date) do
        {:ok, _} -> valid()
        {:error, _} -> invalid(field, "must be MM/DD/YYYY")
      end
    end)
  end

  defp valid(), do: []
  defp invalid(field, message), do: [{field, message}]
end
