defmodule EpicenterWeb.Multiselect do
  use Phoenix.HTML

  alias Epicenter.Extra

  def multiselect_inputs(f, field, values, parent_id \\ nil) do
    inputs =
      for value <- values do
        {:safe, input} = multiselect_input(f, field, value, parent_id)
        input
      end

    {:safe, inputs}
  end

  def multiselect_input(f, field, {type, label_text, value, children}, parent_id) do
    {:safe, parent_input} = multiselect_input(f, field, {type, label_text, value}, parent_id)
    {:safe, child_inputs} = multiselect_inputs(f, field, children, input_id(f, field, value))
    {:safe, [parent_input] ++ child_inputs}
  end

  def multiselect_input(f, field, {type, label_text, value}, parent_id) do
    level = if parent_id == nil, do: "parent", else: "child"

    label data: [multiselect: level, role: Extra.String.dasherize([f.name, field])] do
      case type do
        :checkbox -> [multiselect_checkbox(f, field, value, parent_id), label_text]
        :radio -> [multiselect_radio(f, field, value, parent_id), label_text]
      end
    end
  end

  def multiselect_checkbox(f, field, value, parent_id) do
    form_field_value = input_value(f, field)

    checkbox(
      f,
      field,
      id: input_id(f, field, value),
      name: multiselect_input_name(f, field),
      checked: !is_nil(form_field_value) && value in form_field_value,
      checked_value: value,
      hidden_input: false,
      phx_hook: "Multiselect",
      data: [multiselect: [parent_id: parent_id]]
    )
  end

  def multiselect_radio(f, field, value, parent_id) do
    checked =
      case input_value(f, field) do
        nil -> false
        list when is_list(list) -> value in list
        other -> value == other
      end

    radio_button(
      f,
      field,
      value,
      checked: checked,
      name: multiselect_input_name(f, field),
      phx_hook: "Multiselect",
      data: [multiselect: [parent_id: parent_id]]
    )
  end

  def multiselect_input_name(f, field) do
    input_name(f, field) <> "[]"
  end
end
