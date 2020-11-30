defmodule EpicenterWeb.Multiselect do
  use Phoenix.HTML

  alias Epicenter.Extra

  def multiselect_inputs(f, field, specs, level \\ :parent) do
    inputs =
      for spec <- specs do
        {:safe, input} = multiselect_input(f, field, spec, level)
        input
      end

    {:safe, inputs}
  end

  def multiselect_input(f, field, {type, option_label, option_value, children} = _spec, _level) do
    {:safe, parent_input} = multiselect_input(f, field, {type, option_label, option_value}, :parent)
    {:safe, child_inputs} = multiselect_inputs(f, [field, option_value], children, :child)
    {:safe, [parent_input] ++ child_inputs}
  end

  def multiselect_input(f, field, {type, option_label, option_value} = _spec, level) do
    content_tag :div, class: "label-wrapper" do
      label data: [multiselect: level, role: Extra.String.dasherize([f.name, field])] do
        case type do
          :checkbox -> [multiselect_chradio(f, field, option_value, :checkbox), option_label]
          :radio -> [multiselect_chradio(f, field, option_value, :radio), option_label]
          :other_checkbox -> [multiselect_other(f, field, option_label, :checkbox)]
          :other_radio -> [multiselect_other(f, field, option_label, :radio)]
        end
      end
    end
  end

  def multiselect_chradio(f, field, value, type) when type in [:checkbox, :radio] do
    selected_values =
      case field do
        [field, _subfield] -> input_value(f, field)
        field -> input_value(f, field)
      end

    {field, _subfield, keypath} =
      case field do
        [field, subfield] ->
          if is_map(selected_values),
            do: {field, subfield, ["detailed", subfield, "values"]},
            else: {field, subfield, [subfield]}

        field ->
          if is_map(selected_values),
            do: {field, nil, ["major", "values"]},
            else: {field, nil, []}
      end

    checked =
      cond do
        is_map(selected_values) -> checked?(value, selected_values, keypath)
        is_list(selected_values) -> checked?(value, selected_values)
        true -> checked?(value, selected_values)
      end

    name =
      cond do
        is_map(selected_values) or is_list(selected_values) -> nested_name(f, field, keypath, :multi)
        true -> nested_name(f, field, keypath, :single)
      end

    tag(
      :input,
      checked: checked,
      id: input_id(f, field, value),
      name: name,
      type: type,
      value: html_escape(value)
    )
  end

  def multiselect_text(f, field) do
    {field, _subfield, keypath} =
      case field do
        [field, subfield] -> {field, subfield, ["detailed", subfield, "other"]}
        field -> {field, nil, ["major", "other"]}
      end

    content_tag :div, data: [multiselect: "text-wrapper"] do
      text_input(
        f,
        field,
        id: input_id(f, field, "_other"),
        name: nested_name(f, field, keypath, :single),
        placeholder: "Please specify",
        value: input_value(f, field) |> get_in(keypath) || ""
      )
    end
  end

  def multiselect_other(f, field, option_label, type) when type in [:checkbox, :radio] do
    text_field = multiselect_text(f, field)

    {field, subfield, keypath} =
      case field do
        [field, subfield] -> {field, subfield, ["detailed", subfield, "other"]}
        field -> {field, nil, ["major", "other"]}
      end

    selected_values = input_value(f, field)
    other_checkbox_checked = checked?("true", selected_values, ["_ignore" | keypath])
    other_field_has_value = get_in(selected_values, keypath) |> Euclid.Exists.present?()

    chradio =
      tag(
        :input,
        checked: other_checkbox_checked || other_field_has_value,
        id: input_id(f, Extra.String.underscore([field, subfield, "other"])),
        name: nested_name(f, field, ["_ignore" | keypath], :single),
        type: type,
        value: "true"
      )

    [chradio, option_label, text_field] |> to_safe()
  end

  # # #

  def checked?(value, map, keys) when is_map(map) and is_list(keys),
    do: checked?(value, get_in(map, keys) || [])

  def checked?(value, list) when is_list(list),
    do: list |> Enum.any?(&checked?(value, &1))

  def checked?(value, scalar),
    do: html_escape(value) == html_escape(scalar)

  def nested_name(f, field, keypath, selection_type) when selection_type in [:single, :multi] do
    path = keypath |> Enum.map(fn key -> "[#{key}]" end) |> Enum.join("")
    suffix = if selection_type == :multi, do: "[]", else: ""
    "#{input_name(f, field)}#{path}#{suffix}"
  end

  defp to_safe(list) when is_list(list),
    do: {:safe, list |> Enum.map(&to_safe/1) |> Enum.map(fn {:safe, contents} -> contents end)}

  defp to_safe(other),
    do: html_escape(other)
end
