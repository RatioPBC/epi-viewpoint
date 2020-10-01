defmodule Epicenter.Extra.Changeset do
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
