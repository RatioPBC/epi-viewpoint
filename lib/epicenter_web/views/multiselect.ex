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
    child_field = Extra.String.underscore([field, value]) |> Euclid.Extra.Atom.from_string()
    {:safe, parent_input} = multiselect_input(f, field, {type, label_text, value}, parent_id)
    {:safe, child_inputs} = multiselect_inputs(f, child_field, children, input_id(f, field, value))
    {:safe, [parent_input] ++ child_inputs}
  end

  def multiselect_input(f, field, {type, label_text, value}, parent_id) do
    level = if parent_id == nil, do: "parent", else: "child"

    content_tag :div, class: "label-wrapper" do
      label data: [multiselect: level, role: Extra.String.dasherize([f.name, field])] do
        case type do
          :checkbox -> [multiselect_checkbox(f, field, value, parent_id), label_text]
          :radio -> [multiselect_radio(f, field, value, parent_id), label_text]
          :other_checkbox -> [multiselect_checkbox(f, field, value, parent_id, true), label_text, multiselect_text(f, field, value)]
          :other_radio -> [multiselect_radio(f, field, value, parent_id, true), label_text, multiselect_text(f, field, value)]
        end
      end
    end
  end

  def multiselect_checkbox(f, field, value, parent_id, other? \\ false) do
    checkbox(
      f,
      field,
      checked: current_value?(f, field, value),
      checked_value: value,
      data: [multiselect: [parent_id: parent_id]],
      hidden_input: false,
      id: input_id(f, field, value),
      name: multiselect_input_name(f, field, other?),
      phx_hook: "Multiselect"
    )
  end

  def multiselect_radio(f, field, value, parent_id, other? \\ false) do
    radio_button(
      f,
      field,
      value,
      checked: current_value?(f, field, value),
      data: [multiselect: [parent_id: parent_id]],
      name: multiselect_input_name(f, field, other?),
      phx_hook: "Multiselect"
    )
  end

  def multiselect_text(f, field, value) do
    content_tag :div, data: [multiselect: "text-wrapper"] do
      text_input(
        f,
        field,
        data: [multiselect: [parent_id: input_id(f, field, value)]],
        disabled: !current_value?(f, field, value),
        name: multiselect_input_name(f, field, true),
        value: value
      )
    end
  end

  # # #

  def multiselect_input_name(f, field, false = _other?),
    do: input_name(f, field) <> "[]"

  def multiselect_input_name(%{name: nil}, field, true = _other?),
    do: "#{to_string(field)}_other"

  def multiselect_input_name(%{name: name}, field, true = _other?)
      when is_atom(field) or is_binary(field),
      do: "#{name}[#{field}_other]"

  def multiselect_input_name(name, field, true = _other?)
      when (is_atom(name) and is_atom(field)) or is_binary(field),
      do: "#{name}[#{field}_other]"

  def current_value?(f, field, value) do
    case input_value(f, field) do
      nil -> false
      list when is_list(list) -> value in list
      other -> value == other
    end
  end
end
