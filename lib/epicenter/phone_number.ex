defmodule Epicenter.PhoneNumber do
  def strip_non_digits_from_number(%Ecto.Changeset{} = changeset, field_name) do
    changeset
    |> Ecto.Changeset.fetch_field(field_name)
    |> elem(1)
    |> case do
      nil -> changeset
      number -> Ecto.Changeset.put_change(changeset, field_name, strip_non_digits_from_number(number))
    end
  end

  defp strip_non_digits_from_number(number) when is_binary(number) do
    number
    |> String.graphemes()
    |> Enum.filter(fn element -> element =~ ~r{\d} end)
    |> Enum.join()
  end
end
