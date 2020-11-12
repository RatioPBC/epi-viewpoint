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
          :other_checkbox -> [multiselect_other(:checkbox, f, field, label_text, parent_id)]
          :other_radio -> [multiselect_other(:radio, f, field, label_text, parent_id)]
        end
      end
    end
  end

  def multiselect_checkbox(f, field, value, parent_id) do
    checkbox(
      f,
      field,
      checked: current_value?(f, field, value),
      checked_value: value,
      data: [multiselect: [parent_id: parent_id]],
      hidden_input: false,
      id: input_id(f, field, value),
      name: multiselect_input_name(f, field),
      phx_hook: "Multiselect"
    )
  end

  def multiselect_radio(f, field, value, parent_id) do
    radio_button(
      f,
      field,
      value,
      checked: current_value?(f, field, value),
      data: [multiselect: [parent_id: parent_id]],
      name: multiselect_input_name(f, field),
      phx_hook: "Multiselect"
    )
  end

  def multiselect_text(f, field, parent_id) do
    content_tag :div, data: [multiselect: "text-wrapper"] do
      text_input(
        f,
        field,
        data: [multiselect: [parent_id: parent_id]],
        name: input_name(f, field)
      )
    end
  end

  def multiselect_other(input_type, f, field, label_text, parent_id) do
    field_name = "#{field}_other" |> Euclid.Extra.Atom.from_string()
    input_name = input_name(f, "#{field_name}__ignore")
    input_value = input_value(f, field_name)
    checked = Euclid.Exists.present?(input_value)
    checkable_id = input_id(f, field, "#{checked}")

    checkable =
      case input_type do
        :checkbox ->
          checkbox(
            f,
            field_name,
            checked: checked,
            checked_value: checked,
            data: [multiselect: [parent_id: parent_id]],
            hidden_input: false,
            id: checkable_id,
            name: input_name,
            phx_hook: "Multiselect"
          )

        :radio ->
          radio_button(
            f,
            field_name,
            checked,
            checked: checked,
            data: [multiselect: [parent_id: parent_id]],
            name: input_name,
            phx_hook: "Multiselect"
          )
      end

    [checkable, label_text, multiselect_text(f, field_name, checkable_id)]
  end

  # # #

  defp multiselect_input_name(f, field),
    do: input_name(f, field) <> "[]"

  defp current_value?(f, field, value) do
    case input_value(f, field) do
      nil -> false
      list when is_list(list) -> value in list
      other -> value == other
    end
  end
end
