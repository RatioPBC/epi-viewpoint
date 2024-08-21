defmodule EpiViewpointWeb.Multiselect.Changeset do
  alias EpiViewpoint.Extra
  alias EpiViewpointWeb.Multiselect.Spec

  def conform(old_changeset, new_changeset, params, params_key, specs) do
    case params |> Map.get("_target") do
      [^params_key | [field | path]] ->
        field = Euclid.Extra.Atom.from_string(field)
        spec = Map.get(specs, field)
        path = path |> List.wrap()
        old_values = Ecto.Changeset.get_field(old_changeset, field)
        new_values = Ecto.Changeset.get_field(new_changeset, field)
        event = event(old_values, new_values, path, spec)
        updated_values = apply_event(new_values, event, spec)
        new_changeset |> Ecto.Changeset.put_change(field, updated_values)

      _ ->
        new_changeset
    end
  end

  def apply_event(values, :nothing, _spec) do
    values
  end

  def apply_event(values, :simple, _spec) do
    values
  end

  def apply_event(_values, {:add, :radio, keypath, added_value}, _spec) do
    Extra.Map.put_in(%{}, keypath, added_value, on_conflict: :replace)
  end

  def apply_event(values, {:add, :checkbox, keypath, _added_value}, spec) do
    values
    |> remove_all_radios(spec)
    |> add_parent(keypath)
  end

  def apply_event(values, {:add, :other, keypath, _added_value}, spec) do
    values
    |> remove_all_radios(spec)
    |> add_parent(keypath)
  end

  def apply_event(values, {:remove, :checkbox, ["major", "values"], removed_value}, _spec) do
    values
    |> Extra.Map.delete_in(["detailed", removed_value])
    |> Extra.Map.delete_in(["_ignore", "detailed", removed_value])
  end

  def apply_event(values, {:remove, :checkbox, ["_ignore", "major", "other"], _removed_value}, _spec) do
    values
    |> Extra.Map.delete_in(["_ignore", "major", "other"])
    |> Extra.Map.delete_in(["major", "other"])
  end

  def apply_event(values, {:remove, :checkbox, ["_ignore", "detailed"], removed_value}, _spec) do
    values
    |> Extra.Map.delete_in(["_ignore", "detailed", removed_value, "other"])
    |> Extra.Map.delete_in(["detailed", removed_value, "other"])
  end

  def apply_event(values, {:remove, :other, keypath, "other"}, _spec) do
    values |> Extra.Map.delete_in(Extra.List.concat(keypath, "other"))
  end

  def apply_event(values, _, _) do
    values
  end

  def event(old, new, keypath, spec) when is_map(old) and is_map(new) do
    old = old |> Extra.Map.get_in(keypath) |> List.wrap()
    new = new |> Extra.Map.get_in(keypath) |> List.wrap()

    added = List.first(new -- old)
    removed = List.first(old -- new)

    case {added, removed, keypath} do
      {"true", _, ["_ignore", "major", "other"]} -> {:add, :other, ["major", "other"], "true"}
      {"true", _, ["_ignore", "detailed", added_value, "other"]} -> {:add, :other, ["detailed", added_value, "other"], "true"}
      {added, _, keypath} when not is_nil(added) -> {:add, Spec.type(added, spec), keypath, added}
      {_, removed, keypath} when not is_nil(removed) -> {:remove, Spec.type(removed, spec), keypath, removed}
      {_, _, ["_ignore", "major", "other"]} -> {:remove, :other, ["major"], "other"}
      {_, _, ["_ignore", "detailed", removed_value, "other"]} -> {:remove, :other, ["detailed", removed_value], "other"}
      _ -> :nothing
    end
  end

  def event(_old, _new, _keypath, _spec) do
    :simple
  end

  def add_parent(values, ["detailed", parent_value, _] = _child_keypath),
    do: Extra.Map.put_in(values, ["major", "values"], parent_value, on_conflict: :list_append)

  def add_parent(values, _other_keypath),
    do: values

  def remove_all_radios(map, spec) do
    old_values = Extra.Map.get_in(map, ["major", "values"]) || []
    new_values = Enum.reject(old_values, fn value -> Spec.type(value, spec) == :radio end)
    Extra.Map.put_in(map, ["major", "values"], new_values, on_conflict: :replace)
  end
end
