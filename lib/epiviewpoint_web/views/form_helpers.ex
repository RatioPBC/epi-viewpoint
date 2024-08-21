defmodule EpiViewpointWeb.FormHelpers do
  import Phoenix.HTML.Form
  use PhoenixHTMLHelpers

  alias EpiViewpointWeb.IconView

  @doc """
  Returns an HTML element that contains a list of checkboxes to be used as a multi-select for a single form field.
  Automatically marks the appropriate checkboxes as checked based on the values in the form data.
  """
  def checkbox_list(form, field, values, opts \\ [], html_opts \\ []) when is_list(values) do
    html_opts = [class: "checkbox-list"] |> Keyword.merge(html_opts)
    other = opts |> Keyword.get(:other)
    other_checkbox_and_text_field = checkbox_and_text_field(form, field, other, values)

    content_tag :div, html_opts do
      checkboxes(form, field, values) ++ List.wrap(other_checkbox_and_text_field)
    end
  end

  defp checkbox_and_text_field(_form, _field, nil = _label_text, _values), do: nil

  defp checkbox_and_text_field(form, field, label_text, predefined_labels_and_values) do
    selected_values = input_value(form, field) || []
    predefined_values = predefined_labels_and_values |> Enum.map(fn {_label, key} -> key end)
    others = Enum.filter(selected_values, fn val -> val not in predefined_values end)
    other_selected? = length(others) > 0
    other_value = if other_selected?, do: Enum.join(others, " "), else: ""

    label(data: [role: input_list_label_role(form, field)]) do
      [
        checkbox(form, field,
          name: input_name(form, "#{field}_other"),
          checked: other_selected?,
          checked_value: true,
          value: "true",
          hidden_input: false
        ),
        label_text,
        text_input(form, field,
          value: other_value,
          name: checkbox_list_input_name(form, field),
          data: [reveal: "when-parent-checked"]
        )
      ]
    end
  end

  defp checkboxes(form, field, values) do
    for value <- values do
      checkbox_with_label(form, field, value)
    end
  end

  def checkbox_with_label(form, field, {label_text, value}),
    do: checkbox_with_label(form, field, value, label_text)

  def checkbox_with_label(form, field, value, label_text) do
    label(data: [role: input_list_label_role(form, field)]) do
      [checkbox_list_checkbox(form, field, value), label_text]
    end
  end

  @doc """
  Returns a checkbox that is meant to be part of a multi-select checkbox control.
  Automatically marks the checkbox as checked if its value is in the form data's list of values.
  """
  def checkbox_list_checkbox(form, field, value) do
    form_field_value = input_value(form, field)

    checkbox(
      form,
      field,
      name: checkbox_list_input_name(form, field),
      checked: !is_nil(form_field_value) && value in form_field_value,
      checked_value: value,
      hidden_input: false
    )
  end

  @doc """
  Returns an input name meant for each checkbox in a list of checkboxes.
  Just appends `[]` to whatever `Phoenix.HTML.Form.input_name` returns.
  """
  def checkbox_list_input_name(form, field) do
    input_name(form, field) <> "[]"
  end

  @doc """
  Returns an HTML element that contains a list of radio buttons.
  Automatically marks the appropriate radio button as checked based on the value in the form data.
  """
  def radio_button_list(form, field, values, opts \\ [], html_opts) when is_list(values) do
    html_opts = [class: "radio-button-list"] |> Keyword.merge(html_opts)
    other = opts |> Keyword.get(:other)

    content_tag :div, html_opts do
      other_button_and_text_field = radio_button_and_text_field(form, field, other, values)
      radio_buttons = radio_buttons(form, field, Enum.reverse(values))

      List.wrap(other_button_and_text_field) ++ radio_buttons
    end
  end

  # A list of radio buttons, each wrapped in a label
  defp radio_buttons(form, field, values) do
    for value <- values do
      radio_button_with_label(form, field, value)
    end
  end

  def radio_button_with_label(form, field, {label_text, value}),
    do: radio_button_with_label(form, field, value, label_text)

  def radio_button_with_label(form, field, value),
    do: radio_button_with_label(form, field, value, Gettext.gettext(EpiViewpoint.Gettext, value))

  def radio_button_with_label(form, field, value, label_text) do
    label(data: [role: input_list_label_role(form, field)]) do
      [radio_button(form, field, value), label_text]
    end
  end

  defp radio_button_and_text_field(_form, _field, nil = _label_text, _predefined_values),
    do: nil

  # A radio button, plus an associated text field that is visible only when the radio button is checked
  defp radio_button_and_text_field(form, field, label_text, predefined_values_or_tuples) do
    predefined_values = predefined_values(predefined_values_or_tuples)
    input_value = input_value(form, field)
    other_selected? = input_value not in predefined_values and input_value != nil
    other_value = if other_selected?, do: input_value, else: ""

    label(data: [role: input_list_label_role(form, field)]) do
      [
        radio_button(form, field, nil, checked: other_selected?),
        label_text,
        text_input(form, field, value: other_value, data: [reveal: "when-parent-checked"])
      ]
    end
  end

  defp predefined_values([{_, _} | _] = values), do: values |> Enum.map(&Kernel.elem(&1, 1))
  defp predefined_values(values), do: values

  defp input_list_label_role(form, field),
    do: [form.name, Atom.to_string(field)] |> Enum.map(&String.replace(&1, "_", "-")) |> Enum.join("-")

  def select_with_wrapper(form, field, options, html_opts \\ []) do
    data = html_opts |> Keyword.get(:data)

    content_tag :div, class: "select-wrapper", data: data do
      [
        IconView.arrow_down_icon(),
        select(form, field, options, html_opts)
      ]
    end
  end
end
