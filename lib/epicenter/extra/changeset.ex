defmodule Epicenter.Extra.Changeset do
  def clear_validation_errors(%Ecto.Changeset{} = changeset) do
    struct!(
      Ecto.Changeset,
      changeset
      |> Map.from_struct()
      |> Enum.map(fn
        {:errors, _val} ->
          {:errors, []}

        {:changes, map_of_changes} ->
          {:changes,
           map_of_changes
           |> Enum.map(fn
             {key, value} when is_list(value) -> {key, Enum.map(value, &clear_validation_errors(&1))}
             {key, %Ecto.Changeset{} = value} -> {key, clear_validation_errors(value)}
             key_value -> key_value
           end)
           |> Map.new()}

        key_value ->
          key_value
      end)
    )
  end

  def clear_validation_errors(not_a_changeset),
    do: not_a_changeset
end
