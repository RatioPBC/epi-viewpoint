defmodule EpicenterWeb.Multiselect do
  import Phoenix.HTML, only: [html_escape: 1]

  alias Epicenter.Extra
  alias Phoenix.HTML.Form
  alias Phoenix.HTML.Tag

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
    Tag.content_tag :div, class: "label-wrapper" do
      Form.label data: [multiselect: level, role: Extra.String.dasherize([f.name, field])] do
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
    input_value = input_value(f, field)
    {field, _subfield, keypath} = field_info(field, input_value)

    name =
      cond do
        is_map(input_value) or is_list(input_value) -> input_name(f, field, keypath, :multi)
        true -> input_name(f, field, keypath, :single)
      end

    Tag.tag(
      :input,
      checked: checked?(value, input_value, keypath),
      id: input_id(f, field, value),
      name: name,
      type: type,
      value: html_escape(value)
    )
  end

  def multiselect_text(f, field) do
    {field, _subfield, keypath} = field_info(field)

    Tag.content_tag :div, data: [multiselect: "text-wrapper"] do
      Form.text_input(
        f,
        field,
        data: [role: "other-text"],
        id: input_id(f, field, "other"),
        name: input_name(f, field, keypath, :single),
        placeholder: "Please specify",
        value: input_value(f, field) |> get_in(keypath) || ""
      )
    end
  end

  def multiselect_other(f, field, option_label, type) when type in [:checkbox, :radio] do
    text_field = multiselect_text(f, field)
    {field, subfield, keypath} = field_info(field)
    selected_values = input_value(f, field)
    other_checkbox_checked = checked?("true", selected_values, ["_ignore" | keypath])
    other_field_has_value = get_in(selected_values, keypath) |> Euclid.Exists.present?()

    chradio =
      Tag.tag(
        :input,
        checked: other_checkbox_checked || other_field_has_value,
        id: input_id(f, [field, subfield], "other"),
        name: input_name(f, field, ["_ignore" | keypath], :single),
        type: type,
        value: "true"
      )

    [chradio, option_label, text_field] |> to_safe()
  end

  # # #

  def checked?(value, map, keys \\ nil)

  def checked?(value, map, keys) when is_map(map) and is_list(keys),
    do: checked?(value, get_in(map, keys) || [])

  def checked?(value, list, _keys) when is_list(list),
    do: list |> Enum.any?(&checked?(value, &1))

  def checked?(value, scalar, _keys),
    do: html_escape(value) == html_escape(scalar)

  def field_info([field, subfield]),
    do: {field, subfield, ["detailed", subfield, "other"]}

  def field_info(field),
    do: {field, nil, ["major", "other"]}

  def field_info([field, subfield], input_value) when is_map(input_value),
    do: {field, subfield, ["detailed", subfield, "values"]}

  def field_info([field, subfield], _input_value),
    do: {field, subfield, [subfield]}

  def field_info(field, input_value) when is_map(input_value),
    do: {field, nil, ["major", "values"]}

  def field_info(field, _input_value),
    do: {field, nil, []}

  def input_id(f, [field, subfield], value) when is_nil(subfield),
    do: Form.input_id(f, field, value)

  def input_id(f, [field, subfield], value),
    do: Form.input_id(f, "#{field}_#{subfield}", value)

  def input_id(f, field, value),
    do: Form.input_id(f, field, value)

  def input_name(f, field, keypath, selection_type) when selection_type in [:single, :multi] do
    path = keypath |> Enum.map(fn key -> "[#{key}]" end) |> Enum.join("")
    suffix = if selection_type == :multi, do: "[]", else: ""
    "#{Form.input_name(f, field)}#{path}#{suffix}"
  end

  def input_value(f, [field, _subfield]),
    do: Form.input_value(f, field)

  def input_value(f, field),
    do: Form.input_value(f, field)

  defp to_safe(list) when is_list(list),
    do: {:safe, list |> Enum.map(&to_safe/1) |> Enum.map(fn {:safe, contents} -> contents end)}

  defp to_safe(other),
    do: html_escape(other)
end
