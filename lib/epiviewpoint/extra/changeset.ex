defmodule EpiViewpoint.Extra.Changeset do
  import Ecto.Changeset, only: [get_change: 2]

  def clear_validation_errors(%Ecto.Changeset{} = changeset),
    do: struct!(Ecto.Changeset, changeset |> Map.from_struct() |> clear_top_level_changeset_validation_errors())

  def clear_validation_errors(not_a_changeset),
    do: not_a_changeset

  defp clear_top_level_changeset_validation_errors(map_of_changes) do
    map_of_changes
    |> Enum.map(fn
      {:errors, _val} -> {:errors, []}
      {:changes, map_of_changes} -> {:changes, map_of_changes |> clear_child_changeset_validations_errors() |> Map.new()}
      key_value -> key_value
    end)
  end

  defp clear_child_changeset_validations_errors(map_of_changes) do
    map_of_changes
    |> Enum.map(fn
      {key, value} when is_list(value) -> {key, Enum.map(value, &clear_validation_errors(&1))}
      {key, %Ecto.Changeset{} = value} -> {key, clear_validation_errors(value)}
      key_value -> key_value
    end)
  end

  def get_field_from_changeset(%Ecto.Changeset{} = changeset, field),
    do: changeset |> Ecto.Changeset.fetch_field(field) |> elem(1)

  def has_error_on_field(%Ecto.Changeset{} = changeset, field_name) do
    Keyword.get(changeset.errors, field_name) != nil
  end

  def maybe_mark_for_deletion(%{data: %{id: nil}} = changeset),
    do: changeset

  def maybe_mark_for_deletion(changeset),
    do: if(get_change(changeset, :delete), do: %{changeset | action: :delete}, else: changeset)

  def rewrite_changeset_error_message(changeset, field, new_error_message) do
    update_in(
      changeset.errors,
      &Enum.map(&1, fn
        {^field, {_, opts}} -> {field, {new_error_message, opts}}
        {_key, _error} = tuple -> tuple
      end)
    )
  end
end
