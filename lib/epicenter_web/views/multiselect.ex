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
        :other_radio -> [multiselect_radio(f, field, value, parent_id, true), label_text, multiselect_text(f, field, value)]
      end
    end
  end

  def multiselect_checkbox(f, field, value, parent_id) do
    checkbox(
      f,
      field,
      id: input_id(f, field, value),
      name: multiselect_input_name(f, field, false),
      checked: current_value?(f, field, value),
      checked_value: value,
      hidden_input: false,
      phx_hook: "Multiselect",
      data: [multiselect: [parent_id: parent_id]]
    )
  end

  def multiselect_radio(f, field, value, parent_id, other? \\ false) do
    radio_button(
      f,
      field,
      value,
      checked: current_value?(f, field, value),
      name: multiselect_input_name(f, field, other?),
      phx_hook: "Multiselect",
      data: [multiselect: [parent_id: parent_id]]
    )
  end

  def multiselect_text(f, field, value) do
    content_tag :div, data: [multiselect: "text-wrapper"] do
      text_input(
        f,
        field,
        disabled: !current_value?(f, field, value),
        name: multiselect_input_name(f, field, false),
        value: value,
        data: [multiselect: [parent_id: input_id(f, field, value)]]
      )
    end
  end

  # # #

  def multiselect_input_name(f, field, false = _other?), do: input_name(f, field) <> "[]"
  def multiselect_input_name(f, field, true = _other?), do: input_name(f, field) <> "_other"

  def current_value?(f, field, value) do
    case input_value(f, field) do
      nil -> false
      list when is_list(list) -> value in list
      other -> value == other
    end
  end
end
